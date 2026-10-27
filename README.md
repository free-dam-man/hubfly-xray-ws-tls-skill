# Hubfly Space · VLESS + WS + TLS 一键复刻

> Hubfly Cell 容器（免费 Shared）：平台边缘终止 TLS，容器内跑 **VLESS + WebSocket（明文）**。  
> 客户端侧：`security=tls` + `type=ws` + 官方子域名 `:443`。

**English:** Build the Alpine multi-stage image in `deploy/`, push (e.g. ttl.sh), create Hubfly container(s) with `UUID` / `PORT=8080` / `WSPATH`. Verified 2026-10-27 Asia/Shanghai from this bot’s box:

| Node | Host | generate_204 | Exit |
|---|---|---|---|
| Hubfly-US-01 | `xray.us3.hubfly.app:443` | **204** | Richardson TX `198.58.118.160` AS63949 |
| Hubfly-EU-01 | `xray-eu.eu1.hubfly.app:443` | **204** | Lauterbourg FR `144.91.83.5` AS51167 Contabo |

Sibling skills:

- [zoho-catalyst-appsail-xhttp-skill](https://github.com/free-dam-man/zoho-catalyst-appsail-xhttp-skill) — Zoho AppSail · XHTTP + TLS
- [light-cloud-xhttp-skill](https://github.com/free-dam-man/light-cloud-xhttp-skill) — Light Cloud · XHTTP
- [wispbyte-xray-ws-skill](https://github.com/free-dam-man/wispbyte-xray-ws-skill) — Pterodactyl 明文 WS 备用
- [homeline-residential-exit-skill](https://github.com/free-dam-man/homeline-residential-exit-skill) — 五国真家宽

---

## 核心教训 / Why Alpine multi-stage

官方 `ghcr.io/xtls/xray-core` **没有 shell**。用 `#!/bin/sh` entrypoint 直接当最终镜像会崩成：

```text
exec /entrypoint.sh: no such file or directory
```

平台日志里的 `seccomp` / `capabilities` 多半是崩溃循环噪声。配方：

```dockerfile
FROM ghcr.io/xtls/xray-core:latest AS src
FROM alpine:3.20
COPY --from=src /usr/local/bin/xray /usr/local/bin/xray
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

本机先 `docker run`：日志出现 `Xray … started`，对 path 做 WS 升级拿到 **101**，再推镜像上 Hubfly。

---

## 架构 / Architecture

```text
Shadowrocket / v2rayN / sing-box / Xray
   │  VLESS + WS + TLS   sni=host=<*.hubfly.app>   :443
   ▼
Hubfly edge (SSL subdomain)
   │  plain HTTP → container :$PORT
   ▼
Alpine container
   └─ entrypoint.sh → xray VLESS/WS path=$WSPATH
        └─ exit = Hubfly region datacenter IP
```

---

## 快速复刻 / Reproduce

1. **Register** [Hubfly Space](https://hubfly.app)（或文档当前域名）。免费 Shared：邮箱验证码、免卡；**360 运行时小时/月是账号级总量**（多容器共享），闲置约 15 分钟休眠。
2. **Build & push**（本机需 Docker buildx）：

```bash
./scripts/build-and-push.sh
# → 打印 IMAGE=ttl.sh/hfx2-xxxxxx:24h
```

或手工：

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ttl.sh/hfx2-$(openssl rand -hex 3):24h --push ./deploy
```

3. Hubfly：**一个项目绑定一个区域**。跨区（usa-central / eu-central / eu-north）要新建项目。
4. Create container **from image** → Shared FREE → env：

| Env | Example | Notes |
|---|---|---|
| `UUID` | 新 UUIDv4 | **必填**；勿提交仓库 |
| `PORT` | `8080` | 平台注入/约定；容器监听此端口 |
| `WSPATH` | `/tk-rail` | 须以 `/` 开头 |

5. 记下 SSL 子域名（形如 `\<name\>.\<region-code\>.hubfly.app`，例：`….us3.hubfly.app` / `….eu1.hubfly.app`）。**免费档不能保留 host TCP 端口**，只能走域名 HTTPS。
6. **Client URL**（占位符）：

```text
vless://<UUID>@<HOST>:443?encryption=none&security=tls&type=ws&host=<HOST>&path=<urlencoded WSPATH>&sni=<HOST>#Hubfly-XX
```

Helper: `scripts/make_vless_url.sh`

7. **Verify**：真实客户端 → SOCKS → `https://www.gstatic.com/generate_204` 期望 **204**，再查出口城市/IP。面板 Online / HubProxy  alone **不算**验收。

8. **ttl.sh 过期**：标签约 24h 失效。已在跑的容器不受影响；**删容器重建前**必须从 `deploy/` 重新 buildx 推新标签。

---

## 仓库内容 / Layout

```text
deploy/Dockerfile      # Alpine multi-stage + xray binary
deploy/entrypoint.sh   # UUID/PORT/WSPATH → config → exec xray
scripts/build-and-push.sh
scripts/make_vless_url.sh
docs/TECH.md           # scrubbed platform notes
docs/TECH_NOTE.md      # scrubbed operator note (no secrets)
SKILL.md
LICENSE                # MIT
```

Defaults use **placeholders**. Never publish live UUID、Hubfly 账密、Outlook / 一次性邮箱、或可解码的真订阅。

---

## 诚实限制 / Honest limits

- **360h/月账号级共享** — 双容器常开大约半个月耗尽；靠 15 分钟闲置休眠续命。
- **ttl.sh 24h** — 重建容器前必须重新推镜像（或换自有 registry）。
- **免费无 host 端口** — 不能玩 REALITY / 直连；只能 WS+TLS 走域名。
- **出口 = 机房 IP** — US 侧常见 Linode/Akamai，EU 侧常见 Contabo；不是真家宽。
- **WS 在新 Xray 已标废弃** — 日常中国入口仍优先 Zoho / Light Cloud 的 XHTTP+TLS 兄弟技能。
- **条款** — 平台禁「供他人滥用的开放代理」；自用复刻、勿公开滥发开放中继。
- Hubfly 账单横幅「余额 $0 / 欠费删容器」：实测余额 $0 时免费容器仍可跑，先观察。

---

## One-liner 口令 / Agent prompt

```text
照本仓库 deploy/：Alpine 多阶段拷 xray，推 ttl.sh，Hubfly 按区建项目填 UUID+PORT=8080+WSPATH，客户端 VLESS+WS+TLS 走 *.hubfly.app:443；generate_204 不过别发链接；ttl.sh 过期重建前先重新推镜像；勿提交真 UUID/账密。
```

---

## License

MIT — copy, fork, teach. Freedom / no-walls.
