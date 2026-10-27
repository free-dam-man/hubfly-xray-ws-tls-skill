# Hubfly Space (and similar container PaaS): official xray image has NO shell.
# Multi-stage: copy binary into Alpine so entrypoint.sh can generate config from env.
FROM ghcr.io/xtls/xray-core:latest AS src
FROM alpine:3.20
COPY --from=src /usr/local/bin/xray /usr/local/bin/xray
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
