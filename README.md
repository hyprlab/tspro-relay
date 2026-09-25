# TS Pro Relay

[![Docker Hub](https://img.shields.io/badge/docker-hyprlab%2Ftspro--relay-2496ED?logo=docker&logoColor=white)](https://hub.docker.com/r/hyprlab/tspro-relay)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)

A small self-hosted **outbound email relay** for
[Trusted Servants Pro](https://hub.docker.com/r/hyprlab/trusted-servants-pro),
for running the portal on hosts that **block outbound SMTP ports**
(25/465/587), most notably DigitalOcean droplets, but also many other
cloud providers.

Instead of the app connecting to an SMTP server directly, it POSTs each
message as JSON to this relay over **HTTPS** (behind a reverse proxy).
The relay runs somewhere with SMTP egress and performs the actual
delivery. SMTP credentials live only on the relay, never in the app's
database.

```
TSP app  ──HTTPS──▶  TS Pro Relay  ──SMTP:587/465──▶  mail server
(no SMTP egress)     (this repo)                      (Gmail, SES, …)
```

## Admin interface

The relay ships a **web interface with a login** so an operator can set
everything up without editing JSON or env files:

- **Transaction Log**: every send (and unauthorized attempt) with
  status, sender, recipients, subject, and any error. Counters for
  total / sent / failed / unauthorized.
- **Settings**: the upstream SMTP server, a one-click **API key**
  (reveal / copy / regenerate), an allowed-sender allowlist, attachment
  size limit, a **Send test email** button, optional **Cloudflare
  Turnstile** bot protection on the login page, and the **admin
  password**.

Configuration and the log are stored in a SQLite DB on the `./data`
volume. The SMTP password and API key are encrypted at rest with a key
derived from `RELAY_SECRET_KEY`.

## Install

The published image is on Docker Hub as
[`hyprlab/tspro-relay`](https://hub.docker.com/r/hyprlab/tspro-relay).
You don't need to clone this repo to run it, just a `docker-compose.yml`
and a `.env`.

### 1. Create a working directory

```bash
mkdir tspro-relay && cd tspro-relay
```

### 2. Create `docker-compose.yml`

```yaml
services:
  relay:
    image: hyprlab/tspro-relay:latest
    # The relay serves BOTH the admin UI and the JSON send API on one port.
    # In production put a TLS-terminating reverse proxy in front (see below)
    # and have the TSP app POST to the https:// URL.
    ports:
      - "0.0.0.0:8026:8000"
    environment:
      # Signs sessions AND derives the at-rest encryption key for the
      # stored SMTP password + API key. REQUIRED: set a long random value.
      #   python -c "import secrets; print(secrets.token_urlsafe(48))"
      - RELAY_SECRET_KEY=${RELAY_SECRET_KEY:?set RELAY_SECRET_KEY in .env}
      # First-boot admin login (ignored once the admin row exists).
      # REQUIRED: there is no admin/admin fallback.
      - RELAY_ADMIN_USER=${RELAY_ADMIN_USER:-admin}
      - RELAY_ADMIN_PASSWORD=${RELAY_ADMIN_PASSWORD:?set RELAY_ADMIN_PASSWORD in .env}
      - RELAY_LOG_LEVEL=${RELAY_LOG_LEVEL:-INFO}
      # Set to 1 ONLY for local HTTP testing without TLS.
      - RELAY_INSECURE_COOKIES=${RELAY_INSECURE_COOKIES:-}
      # Reverse proxies (IPs/CIDRs) whose X-Forwarded-For may be trusted
      # for logged client IPs. Leave blank to log the direct peer.
      - RELAY_TRUSTED_PROXIES=${RELAY_TRUSTED_PROXIES:-}
      # Per-IP ceiling on /api/send requests per hour (0 disables).
      - RELAY_SEND_PER_HOUR=${RELAY_SEND_PER_HOUR:-60}
    volumes:
      - ./data:/data        # relay.db (settings, admin, transaction log)
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/healthz',timeout=5).status==200 else 1)"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
```

### 3. Create `.env`

```bash
# Signs login sessions AND encrypts the stored SMTP password + API key.
# REQUIRED. Generate a strong value:
#   python -c "import secrets; print(secrets.token_urlsafe(48))"
RELAY_SECRET_KEY=replace-with-a-long-random-value

# First-boot admin login (change the password from the UI afterwards).
# REQUIRED: the container refuses to start without a password.
RELAY_ADMIN_USER=admin
RELAY_ADMIN_PASSWORD=change-me-on-first-login
```

### 4. Start it

```bash
docker compose up -d
```

The relay (UI + API) is now on **port 8026**. Open `http://<host>:8026`,
sign in, and on **Settings** fill in your SMTP server and copy the API
key.

> **Building from source instead?** Clone this repo and use
> `image:` → `build: .` in the compose file, then
> `docker compose up -d --build`.

## Before it faces the internet

The login cookie and the Bearer API key must never cross plain HTTP. Put a
TLS-terminating reverse proxy in front of port 8026, then point the TSP app at
the `https://` URL in **Settings → Domain / Email**. The proxy examples, the
TSP app settings and the operator checklist are in the documentation below.

## Documentation

| | |
| --- | --- |
| [Setup and configuration](docs/DOCUMENTATION.md) | TLS, connecting the TSP app, environment variables, upgrading, the local test stack |
| [API](docs/API.md) | `POST /api/send`, `GET /api/health`, `GET /healthz` |
| [Security](docs/SECURITY.md) | What the relay defends against, the operator checklist, reporting a problem |
| [Changelog](CHANGELOG.md) | Every release |
| [Contributing](docs/CONTRIBUTING.md) | Commits, credit, and how releases are made |

## AI notice

TS Pro Relay is built by a human maintainer working with generative AI as a development tool:

- **Code**: the large majority of the Python code in this repository was written with Anthropic's Claude (via Claude Code), working from the maintainer's direction. The maintainer decides what gets built, reviews the results, tests every release, and signs off on everything that ships.
- **Text**: documentation, release notes, and in-app copy are largely AI-drafted and human-edited.
- **Commits** are made under the maintainer's name. The tool is declared here once, for the whole repository, instead of in a trailer on every commit.
- **The app itself contains no AI.** The relay has no AI features and makes no requests to AI services. It only accepts mail from your TS Pro instance and hands it to your SMTP provider. AI was used to *build* the app, not to run it.

Bug reports and pull requests are welcome from humans and their AI tools alike; everything merged gets the same human review.

## License

Released under the **GNU Affero General Public License v3.0**; see
[LICENSE](LICENSE). If you run a modified version as a network service,
the AGPL requires you to offer your users the corresponding source.
