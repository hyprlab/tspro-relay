# Setup and configuration

Installing is in the [README](../README.md#install). This page covers what
comes after: TLS, connecting the TSP app, the environment variables,
upgrading, and the local test stack.

## TLS in production

The login cookie and Bearer token must never cross plaintext. Put a
reverse proxy in front that terminates HTTPS and proxies to
`127.0.0.1:8026`.

**Caddy**
```
relay.example.com {
    reverse_proxy 127.0.0.1:8026
}
```

**nginx**
```
location / {
    proxy_pass http://127.0.0.1:8026;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $remote_addr;
}
```

Then point the TSP app at `https://relay.example.com`.

Two proxy-related settings worth adding:

- **HSTS**: the relay does not emit `Strict-Transport-Security` itself
  (it never knows whether TLS is in play); set it at the proxy, e.g.
  nginx `add_header Strict-Transport-Security "max-age=31536000" always;`
  (Caddy sends sensible defaults with a `header` directive).
- **`RELAY_TRUSTED_PROXIES`** (optional): by default the relay trusts
  `X-Forwarded-For` as-is for the client IPs shown in the Transaction
  Log, which works out of the box behind one proxy hop but lets a
  direct client spoof its logged address. Set this to your proxy's
  address as seen by the relay (for the compose setup above, the docker
  bridge, e.g. `172.16.0.0/12`) to honour the header only from your
  proxy and make logged IPs spoof-proof.

## Configure the TSP app

In the portal: **Settings → Domain / Email**

1. **Sending method** → *API relay (HTTPS)*
2. **Relay URL** → `https://relay.example.com`
3. **Relay API key** → the key from the relay's Settings page
4. **From email / From name** → your sender identity
5. **Save Email Settings**, then **Send Test**. The result also lands in
   the relay's Transaction Log.

## Environment variables

| Var | Required | Default | Notes |
|-----|----------|---------|-------|
| `RELAY_SECRET_KEY` | ✅ | | Signs sessions + encrypts stored secrets (HKDF-derived keys). The relay **refuses to start** without it. Keep it stable: rotating it invalidates the stored SMTP password + API key. Use 32+ chars. |
| `RELAY_ADMIN_USER` | | `admin` | First-boot admin username. |
| `RELAY_ADMIN_PASSWORD` | ✅ | | First-boot password (compose refuses to start without it). If it is ever seeded as `admin`, the UI forces a password change at first login. |
| `RELAY_TRUSTED_PROXIES` | | | Comma-separated IPs/CIDRs of reverse proxies. Blank = `X-Forwarded-For` trusted as-is (logged IPs are spoofable); set = header honoured only from these addresses. |
| `RELAY_SEND_PER_HOUR` | | `60` | Per-IP ceiling on `/api/send` requests per hour; `0` disables. Login is separately throttled (5 failures/minute per IP). |
| `RELAY_LOG_LEVEL` | | `INFO` | `DEBUG` \| `INFO` \| `WARNING` \| `ERROR`. |
| `RELAY_INSECURE_COOKIES` | | | Set `1` only for local HTTP testing (no TLS). |
| `RELAY_DATA_DIR` | | `/data` | Where `relay.db` lives. |

Everything else (SMTP host/port/security/credentials, API key, allowed
senders, attachment limit, Turnstile keys) is managed from the
**Settings** page.

## Upgrading

```bash
docker compose pull && docker compose up -d
```

Each release's changes are in the [changelog](../CHANGELOG.md). The image is
published as `hyprlab/tspro-relay:X.Y.Z`, `:X.Y` and `:latest`; pin a version
in `image:` to upgrade only when you choose to.

## Local end-to-end test

`docker-compose.test.yml` brings up the relay built from source plus a
**Mailpit** SMTP sink to verify delivery. Both the relay UI and Mailpit's inbox
are bound to localhost only, and the stack requires `RELAY_SECRET_KEY` and
`RELAY_ADMIN_PASSWORD`. `tools/redeploy.sh` builds and starts it, creating a
git-ignored `.env.test` with random values the first time:

```bash
tools/redeploy.sh          # relay on 127.0.0.1:8026, Mailpit on 127.0.0.1:8027
tools/redeploy.sh down
```
