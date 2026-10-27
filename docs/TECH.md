# Hubfly Space · scrubbed tech notes

## Platform (verified 2026-10-27 Asia/Shanghai)

- Product: Hubfly Space Cell containers, free **Shared** tier.
- Deploy modes: Git, **container image**, template, Compose; also KVM VMs. This skill uses **image**.
- Ingress: default SSL subdomain `<container>-<project>.<region-code>.hubfly.app` (suffix `.hubfly.app`, not `.hubfly.space`). Free tier **cannot reserve host TCP/UDP ports** → must use HTTPS domain edge.
- Regions: `eu-central`, `eu-north`, `usa-central`. **One project = one region**; cross-region needs a new project.
- Quota: **360 runtime hours / month are account-wide**, shared across free containers (panel copy that says “per container” is misleading). Idle ~15 minutes → sleep to save hours.
- ToS §4 style language: bans open proxies/relays “for others to abuse”; platform itself sells tunnel/proxy templates. Self-use only; do not publish open relays.

## Image lesson

`FROM ghcr.io/xtls/xray-core` as the **final** image + shell entrypoint → crash loop (`no such file or directory`). Root cause: **no `/bin/sh` in official image**. Fix: Alpine multi-stage `COPY` binary + `entrypoint.sh` (see `deploy/`).

Local gate before Hubfly: `docker run` shows Xray started; curl WS upgrade to path returns **101**.

Ephemeral push: `ttl.sh/<name>:24h` (multi-arch amd64+arm64). After expiry, rebuild before recreating containers. Running containers keep their already-pulled layers.

## Env

| Key | Typical | Notes |
|---|---|---|
| `UUID` | UUIDv4 | rotate per deploy |
| `PORT` | `8080` | listen inside container |
| `WSPATH` | `/…` | must start with `/` |

## Client

- Port **443**, `security=tls`, `type=ws`, `sni` = `host` = Hubfly subdomain.
- Inside container traffic to xray is plaintext WS on `$PORT` (edge already terminated TLS).

## E2E (box, 2026-10-27 ~23:13 Asia/Shanghai)

| Tag | Host | generate_204 | Exit |
|---|---|---|---|
| US | `xray.us3.hubfly.app` | 204 | `198.58.118.160` Richardson TX AS63949 |
| EU | `xray-eu.eu1.hubfly.app` | 204 | `144.91.83.5` Lauterbourg FR AS51167 |

TLS probe to `/` → HTTP 404 (expected). WS upgrade without VLESS → HTTP 400 (listener alive).

## Ops hygiene

- Save credentials to a local `*.env` **before** deploy (gitignored). Do not rely on chat history.
- Subscription merge: join VLESS lines with newlines, then base64; **decode and re-check** (missing trailing newline glues two links into one).
- Prefer a domainized sub front (CDN) so public links never show the origin VPS IP; confirm edge cache is DYNAMIC for that path.
