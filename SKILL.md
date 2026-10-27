# hubfly-xray-ws-tls-skill

## When to use
Someone wants a **reproducible** node on **Hubfly Space** (Cell container, free Shared) or a similar PaaS that:
- gives an **HTTPS subdomain** (edge TLS),
- forwards plain HTTP to container `$PORT`,
- does **not** allow free-tier host TCP ports.

Protocol on the wire to clients: **VLESS + WebSocket + TLS** (`security=tls`, `type=ws`). Inside the container: WS plaintext on `$PORT`.

## Do
1. Build Alpine multi-stage image from `deploy/` (official `xray-core` image has **no shell** — do not use it as runtime `FROM` with a shell entrypoint).
2. Push to an ephemeral registry (e.g. `ttl.sh/...:24h`) or your own registry.
3. Hubfly: one project per region → Create from image → env `UUID`, `PORT=8080`, `WSPATH`.
4. Client: `type=ws&security=tls&sni=<hubfly-subdomain>&host=<same>&path=<WSPATH>` on port **443**.
5. E2E: real client → SOCKS → `generate_204=204` + exit IP/city. Scrub secrets before any public commit.
6. Before recreating a container after ttl.sh expiry: rebuild + push a fresh tag from `deploy/`.

## Don't
- Don't `FROM ghcr.io/xtls/xray-core` as the final image if entrypoint needs `/bin/sh`.
- Don't commit live UUID, Hubfly passwords, Outlook / disposable mail, `hubfly.env`, or decodeable live subscription blobs.
- Don't assume free Shared has host port mapping — it does not.
- Don't treat panel "Online" / HubProxy 200 as success without E2E.
- Don't call Contabo / Linode exit "真家宽".
