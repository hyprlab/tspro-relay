# API

The JSON API the Trusted Servants Pro portal calls. Every request travels
over HTTPS through the reverse proxy ([TLS](DOCUMENTATION.md#tls-in-production)).

## `POST /api/send`
Header: `Authorization: Bearer <api-key>` · Body: JSON

```json
{
  "from_email": "noreply@example.com",
  "from_name": "Trusted Servants Pro",
  "to": ["someone@example.org"],
  "subject": "Hello",
  "text": "Plain-text body",
  "html": "<p>Optional HTML body</p>",
  "reply_to": "replies@example.org",
  "reply_to_name": "Replies",
  "attachments": [
    {"filename": "doc.pdf", "mime_type": "application/pdf", "content_b64": "..."}
  ]
}
```

`200 {"ok": true}` on success; otherwise `{"ok": false, "error": "..."}`
with `401` (bad key), `403` (From not allowed), `413` (attachments or
request body too big), `429` (per-IP rate limit — see
`RELAY_SEND_PER_HOUR`), or `502` (SMTP failed — the response is generic;
delivery details appear only in the relay's Transaction Log). Messages
are capped at 100 recipients (`400`).

## `GET /healthz`
Unauthenticated liveness probe; returns `{"ok": true}` only.
Configuration state is available to authenticated callers via
`GET /api/health` (Bearer-authenticated).
