# Security

## Reporting a problem

Report security problems privately by email to hyprlab@proton.me. Please
don't open a public issue.

Expect a reply within a week. A fix ships as an urgent patch release
([RELEASING.md](RELEASING.md#urgent-patches)), the reporter is credited in the
changelog unless they ask not to be, and an embargo the reporter proposes is
respected, ending when the fixed release ships. Serious issues get a GitHub
Security Advisory, and a CVE where one is warranted.

Only the latest release receives security fixes.

## What the relay defends against

- Sessions and at-rest encryption keys are HKDF-derived from
  `RELAY_SECRET_KEY`; the relay refuses to boot without one.
- Forced password change whenever the admin account carries the seeded
  default password.
- Login lockout (5 failures/minute per IP) and a per-IP `/api/send`
  ceiling (`RELAY_SEND_PER_HOUR`).
- Security response headers on every page (CSP, `X-Frame-Options`,
  `X-Content-Type-Options`, `Referrer-Policy`).
- 100-recipient cap per message; SMTP error details are kept out of API
  responses (they appear in the Transaction Log only).
- Settings/credential changes and log clears are recorded in a
  `settings_audit` table inside `relay.db` (who / when / from where).
- The container runs as an unprivileged user (uid 1000).

## Operator checklist

- Always run the UI + API behind TLS in production, and set **HSTS** at
  the reverse proxy ([TLS in production](DOCUMENTATION.md#tls-in-production)).
- **Populate the Allowed From list.** Blank accepts any sender — set it
  so a leaked key can't spoof arbitrary addresses.
- Keep `RELAY_SECRET_KEY` long (32+ chars), random, and stable.
- Set `RELAY_TRUSTED_PROXIES` if you want Transaction Log IPs to be
  spoof-proof (by default the `X-Forwarded-For` header is trusted
  as-is).
- The API key is a plain bearer token with no replay protection — TLS
  end-to-end between the TSP app and the relay is what protects it.
- Optionally enable **Cloudflare Turnstile** (Settings → Login bot
  protection) to challenge the sign-in page. The relay needs outbound
  HTTPS to `challenges.cloudflare.com` for verification, and verifies the
  token's `hostname` matches this relay.
