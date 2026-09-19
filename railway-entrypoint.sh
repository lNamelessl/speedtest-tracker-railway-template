#!/bin/bash
# Railway boot wrapper for linuxserver/speedtest-tracker.
#
# NOTE: plain bash, NOT with-contenv - this runs BEFORE /init, so s6's
# container_environment envdir does not exist yet. Exported variables are
# inherited by /init, which copies them into the s6 environment (the same
# mechanism `docker -e APP_KEY=...` uses, which the upstream image supports).
#
# Purpose: guarantee a valid Laravel APP_KEY on every deploy.
#
# Upstream contract (verified from linuxserver/docker-speedtest-tracker):
#   init-speedtest-tracker-config HALTS the container (`sleep infinity`) when
#   APP_KEY is empty and no key is present in the .env file. Laravel requires
#   the format `base64:<44-char base64 of 32 random bytes>`.
#
# Idempotency contract:
#   - Railway `secret()` expressions cannot produce valid base64 Laravel keys,
#     so the key is generated here (32 bytes from /dev/urandom) on first boot
#     and persisted to /config/railway-appkey (the persistent volume).
#   - An explicitly set APP_KEY service variable always wins and is persisted
#     (restore-from-backup / BYO-key path).
#   - Removing a previously set APP_KEY variable does NOT rotate the key:
#     the persisted copy keeps protecting already-encrypted data.
#   - NEVER rotate this key after results exist: Laravel's crypt uses APP_KEY,
#     and rotating it makes every stored encrypted value unreadable.

set -e

KEYFILE="/config/railway-appkey"
mkdir -p /config

if [ -n "${APP_KEY:-}" ]; then
    echo "[railway-key] APP_KEY provided via service variable - persisting it"
    printf '%s' "$APP_KEY" > "$KEYFILE"
elif [ -f "$KEYFILE" ]; then
    echo "[railway-key] Reusing persisted APP_KEY from $KEYFILE"
    export APP_KEY="$(tr -d '\n' < "$KEYFILE")"
else
    echo "[railway-key] Fresh volume - generating a new random APP_KEY (never rotate it afterwards)"
    export APP_KEY="base64:$(head -c 32 /dev/urandom | base64 | tr -d '\n')"
    printf '%s' "$APP_KEY" > "$KEYFILE"
fi

if ! printf '%s' "$APP_KEY" | grep -qE '^base64:[A-Za-z0-9+/]{43}=$'; then
    echo "[railway-key] WARNING: APP_KEY does not match the expected 'base64:<44 chars>' format."
    echo "[railway-key] The upstream init will halt the container if Laravel rejects it."
fi

chmod 644 "$KEYFILE"

echo "[railway-key] Handing off to upstream init"
exec /init "$@"
