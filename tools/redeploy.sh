#!/usr/bin/env bash
# Rebuild the local test stack from the working tree and restart it, so a
# change can be tried at once: the relay on http://127.0.0.1:8026 and Mailpit,
# which catches every message it sends, on http://127.0.0.1:8027. Both are
# bound to localhost only. It publishes nothing.
#
#   tools/redeploy.sh          # rebuild and restart
#   tools/redeploy.sh down     # stop the stack
#
# The stack needs RELAY_SECRET_KEY and RELAY_ADMIN_PASSWORD. They are read
# from .env.test (git ignores it), which the first run creates with random
# values; the admin password is printed so you can sign in.
set -euo pipefail
cd "$(dirname "$0")/.."

compose=(docker compose -f docker-compose.test.yml --env-file .env.test)

if [ "${1:-}" = down ]; then
    "${compose[@]}" down
    exit 0
fi

if [ ! -f .env.test ]; then
    umask 077
    python3 - > .env.test <<'PY'
import secrets
print(f"RELAY_SECRET_KEY={secrets.token_urlsafe(48)}")
print(f"RELAY_ADMIN_PASSWORD={secrets.token_urlsafe(12)}")
PY
    echo "Created .env.test with a random secret key and admin password."
fi
# The TSP app reaches the relay over this network; the stack expects it.
docker network inspect tspro_default >/dev/null 2>&1 || docker network create tspro_default >/dev/null

mkdir -p data-test
"${compose[@]}" up -d --build
for _ in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:8026/healthz >/dev/null 2>&1; then
        version=$(sed -n 's/^__version__ = "\(.*\)"/\1/p' relay.py)
        echo "Up: relay $version (working tree) on http://127.0.0.1:8026, Mailpit on http://127.0.0.1:8027"
        echo "Sign in as admin / $(sed -n 's/^RELAY_ADMIN_PASSWORD=//p' .env.test)"
        exit 0
    fi
    sleep 1
done
echo "The relay did not become healthy. Logs:" >&2
"${compose[@]}" logs --tail 40 relay-test >&2
exit 1
