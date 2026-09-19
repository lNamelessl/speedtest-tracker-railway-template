# Speedtest Tracker — continuous internet-speed monitoring on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/speedtest-template)

Track your internet speed over time — scheduled tests, graphs, history. This template deploys [Speedtest Tracker](https://speedtest-tracker.dev) (the linuxserver.io image, pinned to the stable **1.15.0** build) as a single Railway service with a persistent volume, ready to log its first speedtest minutes after you click deploy.

**What you get:**

- **One service, zero prompts** — the deploy form has no fields to fill in. Nothing to type.
- **APP_KEY handled correctly** — Laravel requires a `base64:`-formatted 32-byte encryption key (the app refuses to boot without one, and Railway's `secret()` generator can't produce this format). A small boot wrapper ([`railway-entrypoint.sh`](https://github.com/lNamelessl/speedtest-tracker-railway-template/blob/main/railway-entrypoint.sh)) generates a proper random key on first boot and persists it on the volume.
- **Scheduled tests built in** — `SPEEDTEST_SCHEDULE` defaults to `0 */6 * * *` (every 6 hours). Change it to any cron expression and redeploy.
- **Persistence** — a Railway volume at `/config` holds the SQLite results database, config, and logs. Results, users, and the APP_KEY survive restarts and redeploys.
- **Healthcheck wired** — uses the app's own unauthenticated `/api/healthcheck` API route.
- **Baked defaults** — `PUID=1000`, `PGID=1000`, `TZ=Etc/UTC`, `DB_CONNECTION=sqlite`, `PRUNE_RESULTS_OLDER_THAN=0` (keep everything forever). Override any of them in the Variables tab.

**Cost:** a single service plus its `/config` volume runs around **$3–5/month** on Railway's usage-based pricing.

# Deploy and Host

Deploying this template provisions one Railway service running the linuxserver.io Speedtest Tracker image (`lscr.io/linuxserver/speedtest-tracker:1.15.0`) with a public domain pinned to the app's web UI on port 80 (Railway terminates TLS at the edge), plus one persistent volume mounted at `/config` for the SQLite database and app config. On first boot the boot wrapper generates the mandatory Laravel `APP_KEY`, the image runs database migrations automatically, and the web UI is reachable at your Railway domain within a couple of minutes.

## About Hosting

Hosting Speedtest Tracker on Railway gives you an always-on measurement point that is independent of your home connection — useful when you want history from a specific region or datacenter. Everything stateful lives in the `/config` volume: results are stored in SQLite (`/config/database.sqlite`), and the app's Laravel log lives under `/config/log/`. The tracker runs tests on schedule through the image's internal scheduler (no extra cron service), and each test is processed by the image's built-in queue worker. Outbound internet access from Railway is standard, so Ookla server selection and tests work out of the box. Because the deployment is single-service, scaling is unnecessary — the tracker is idle between tests.

## Why Deploy

- **Manual installs of the LinuxServer image** require a Docker host, a composed `docker run` command with the right `APP_KEY` format, and a bind mount — this template replaces all of that with one click and a generated key in the correct Laravel format.
- **Default credentials are a real risk on a public URL**: the app ships with `admin@example.com` / `password` and does not force a change. This listing's first step after deploy is to change that password immediately.
- **The APP_KEY trap is pre-solved**: upstream halts the container when the key is missing, and rotating an existing key silently makes stored encrypted data unreadable. The wrapper generates the key once per deploy, persists it, and reuses it across restarts — never rotating behind your back.
- **Graphs need history; history needs a persistent disk.** The volume is provisioned with the template, so your graph starts accumulating from day one instead of resetting on every redeploy.

## Common Use Cases

- **ISP accountability**: run a test every hour (`SPEEDTEST_SCHEDULE=0 * * * *`) and build a graph to compare against your plan's advertised speeds.
- **Datacenter monitoring**: track the bandwidth of a Railway region/VM from the inside.
- **Home-lab continuity**: mirror the setup you run on Proxmox/Unraid, with history that survives redeploys.
- **Automated record keeping**: let `PRUNE_RESULTS_OLDER_THAN` cap retention (in days), or keep everything with `0`.

## Dependencies for

### Deployment Dependencies

- **Railway service**: `lscr.io/linuxserver/speedtest-tracker:1.15.0` (built from the linked GitHub repo's Dockerfile), healthcheck on `/api/healthcheck`.
- **Railway volume**: mounted at `/config` (SQLite database, app key marker, logs). Single volume — one per service, which is all this app needs.
- **Template variables**: none — the deploy form is empty. `APP_KEY` is generated invisibly inside the container on first boot (not stored as a template variable), so there are no prompts and no secrets in the template.
- **Post-deploy steps (you, once)**: open the domain → log in with `admin@example.com` / `password` → **change the password immediately** (user menu → Profile) → click the dashboard's run-test button (or wait for the schedule). Optionally set `SPEEDTEST_SERVERS` to pin preferred Ookla server IDs (list nearby ones via `railway ssh`, then `php /app/www/artisan app:ookla-list-servers`).
- **Never rotate `APP_KEY`** once results exist: encrypted values stored under the old key become unreadable.
