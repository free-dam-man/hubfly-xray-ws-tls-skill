# Hubfly-US-01 / Hubfly-EU-01 部署技术总结（已脱敏）

- 日期：2026-10-27（美国容器当日跑通，欧洲容器当日跑通，均验收交付）
- 平台：Hubfly Space（总部卢旺达），Cell 容器，免费 Shared 档
- 节点：Hubfly-US-01 = `xray.us3.hubfly.app:443`（usa-central）；Hubfly-EU-01 = `xray-eu.eu1.hubfly.app:443`（eu-central）
- 协议：VLESS + WebSocket + TLS，路径示例 `/tk-rail`，双区可共用同一 UUID（自行轮换）
- 出口：美国得州 Richardson `198.58.118.160`（AS63949）；法国 Lauterbourg `144.91.83.5`（AS51167 Contabo）
- 状态：箱内实测 `generate_204=204`（2026-10-27 ~23:13 Asia/Shanghai）。**真实 UUID / 面板账密 / 邮箱密码未写入本仓库。**

## 1. 平台侦察

- 免费 Shared：每月 360 运行时小时 + 存储，免卡；邮箱+验证码注册。
- 部署方式：Git、**容器镜像**、模板、Docker Compose；另有 KVM。本次走镜像。
- 入口：默认 SSL 子域名 `<容器>-<项目>.<区域代码>.hubfly.app`（后缀是 `.hubfly.app`）；也支持公网 TCP/UDP 映射，但**免费档不能保留 host 端口**，只能走域名 HTTPS。
- 区域：eu-central、eu-north、usa-central。**项目按区域绑定**，跨区必须新建项目。
- 条款倾向：禁「供他人滥用的开放代理/中继」；平台自售隧道/代理模板。自用复刻即可。
- 配额真相：360 小时是**账号级总量**，多容器共享；闲置约 15 分钟休眠。

## 2. 镜像（核心教训）

第一版：`FROM ghcr.io/xtls/xray-core:latest` + `#!/bin/sh` entrypoint → 崩溃循环，`no such file or directory`。  
**根因：官方 xray 镜像没有 shell。**

修复（本仓库 `deploy/`）：

```dockerfile
FROM ghcr.io/xtls/xray-core:latest AS src
FROM alpine:3.20
COPY --from=src /usr/local/bin/xray /usr/local/bin/xray
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

上平台前本机验证：日志 `Xray … started`，curl WS 升级 **101**，再推 `ttl.sh/…:24h`（多架构；24h 过期后重建需重新推送）。

## 3. 部署流程（脱敏）

1. 一次性邮箱注册（**勿把邮箱密码写入仓库**；建议本地 `hubfly.env`，已被 `.gitignore`）。
2. 建项目（usa-central）→ 从镜像建容器：Shared FREE、小规格、env `UUID` / `PORT=8080` / `WSPATH=/…`。
3. 平台**不支持原地改镜像** → 删容器重建（同名、同档、同环境变量）。
4. 欧洲：同账号新建项目（eu-central）→ 同镜像同配置，另挂 `*.eu1.hubfly.app`。
5. 账单「余额为零」横幅：实测余额 $0 时免费容器仍可运行；先观察，不急充值。

## 4. 验收

- 客户端：本地 SOCKS → 出站 VLESS+WS+TLS，SNI 与 Host 填各自域名。
- 美国：`generate_204=204`；出口 Richardson。
- 欧洲：`generate_204=204`；出口 Lauterbourg（Contabo）。
- 验收客户端用完即关；勿动生产 VPS 上的面板/业务 xray。

## 5. 交付物（模式说明）

- 单节点订阅 + 合并订阅（base64 标准订阅时**逐行拼接并解码复查**）。
- 订阅可走自有域名 + CDN 反代，避免对外链接暴露源站 IP；确认边缘对该路径不缓存（DYNAMIC）。
- 示例客户端（占位符）：

```text
vless://CHANGE_ME@xray.us3.hubfly.app:443?encryption=none&security=tls&type=ws&host=xray.us3.hubfly.app&path=%2Ftk-rail&sni=xray.us3.hubfly.app#Hubfly-US-01
vless://CHANGE_ME@xray-eu.eu1.hubfly.app:443?encryption=none&security=tls&type=ws&host=xray-eu.eu1.hubfly.app&path=%2Ftk-rail&sni=xray-eu.eu1.hubfly.app#Hubfly-EU-01
```

## 6. 已知缺陷

- ttl.sh 标签约 24h 过期；运行中容器不受影响，重建前必须重新推镜像。
- 360h/月双容器共享；重度使用盯账单余量。
- 凭据应部署前落盘；本仓库刻意不含 `hubfly.env`。
- 免费档无公网 TCP：不能玩 REALITY 等直连。

## 7. 可复用经验

- 新镜像先本机 docker 跑通（进程 + WS 101）再上平台。
- 官方 xray 无 shell → Alpine 多阶段拷贝二进制。
- 面板 seccomp/capabilities 噪声先复现再归因。
- 对外订阅用域名+CDN：链接不露源站 IP。
