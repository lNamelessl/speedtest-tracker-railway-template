# Speedtest Tracker on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/speedtest-template)

[Speedtest Tracker](https://speedtest-tracker.dev) (linuxserver.io image) — track your internet speed over time: scheduled tests, graphs, history — deployed in one click with a persistent results database. Pinned to the stable `lscr.io/linuxserver/speedtest-tracker` **1.15.0** build.

## What you get on deploy

| | |
|---|---|
| App | Speedtest Tracker 1.15.0 (Laravel + SQLite), web UI on your Railway domain (HTTPS at the edge, HTTP inside — that's normal) |
| APP_KEY | **Auto-generated per deploy** (32 random bytes, Laravel `base64:` format) and persisted on the volume — zero form prompts |
| Schedule | Speedtests run on a cron you control: `SPEEDTEST_SCHEDULE`, default `0 */6 * * *` (every 6 hours) |
| Persistence | Railway volume at `/config` — SQLite results DB, config, and logs survive restarts and redeploys |
| Healthcheck | `/api/healthcheck` — the app's own unauthenticated API health route |
| Result retention | `PRUNE_RESULTS_OLDER_THAN=0` (keep everything); change to N days to auto-prune |

There is nothing to type at deploy time — the deploy form shows a single variable (`APP_KEY`) already set to auto-generate.

## First login — change the password immediately

1. Open your deployment's public domain. You land on the login page.
2. Sign in with the default credentials: **`admin@example.com` / `password`**.
3. **Change the password right away** (top-right user menu → **Profile** → *New password*). The app does not force it for you — on a public Railway domain, anyone could otherwise log in and see/run your tests.
4. Click **Run speedtest** on the dashboard and watch the graph populate.

If you see a "Getting Started" page instead, you skipped nothing — it just means the tracker has no results yet; run one manually.

## The APP_KEY warning (read before touching it)

`APP_KEY` encrypts data stored by the app (e.g. webhook/notification settings). The template:

1. generates a fresh random key on first boot (a Railway `secret()` expression can't produce a valid Laravel key),
2. writes it to `/config/railway-appkey` **on the volume**, and
3. reuses that copy on every restart/redeploy.

**Never rotate `APP_KEY` once you have results** — every encrypted value stored under the old key becomes permanently unreadable. If you set `APP_KEY` manually (e.g. restoring a backup), set it as a service variable; the variable wins and is persisted, and removing the variable later falls back to the persisted copy rather than rotating.

## Customizing

- **Schedule**: set `SPEEDTEST_SCHEDULE` to any [cron expression](https://crontab.guru/) — `0 */6 * * *` = every 6 hours, `0 4 * * *` = daily 04:00, `*/30 * * * *` = twice an hour. The app's internal scheduler reads it from the environment (restarts/redeploys pick up changes).
- **Prefer specific speedtest servers**: set `SPEEDTEST_SERVERS` to comma-separated server IDs. Find nearby IDs with:
  `railway ssh` into the service, then `list-servers`.
- **Timezone**: `TZ` (container/cron) and `DISPLAY_TIMEZONE` (how times render in the UI).
- **Pruning**: `PRUNE_RESULTS_OLDER_THAN=30` keeps 30 days of results.
- **Backup**: everything lives in SQLite — copy `/config/database.sqlite` off the volume (`railway ssh`, then use the Railway volume's SFTP/`railway volume` download or `cp` into a synced folder). Restore by placing it back; keep the matching `APP_KEY`.

## Cost

A single Speedtest Tracker service + its `/config` volume runs around **$3–5/month** on Railway's usage-based pricing (idle between tests; the volume is the floor).

## Troubleshooting

| Symptom | Fix |
|---|---|
| Deploy loops with "application key is missing" in logs | The `/config` volume was removed *and* the persisted key file went with it. Re-attach the volume (or set `APP_KEY` manually once). |
| Scheduled tests not firing | Check `SPEEDTEST_SCHEDULE` on crontab.guru (5 fields, spaces included). Restart after editing the variable. |
| Tests fail / "no servers" | Set `SPEEDTEST_SERVERS` to 1–3 nearby server IDs (find them with `list-servers` via `railway ssh`). |
| Everything unreadable after changing APP_KEY | That's the rotation trap — encrypted values under the old key can't be decrypted. Restore the old key or start fresh. |
| Wrong times on the graph | Set `TZ` and `DISPLAY_TIMEZONE` to your IANA zone (e.g. `Europe/Berlin`). |

## Links

- Upstream: https://github.com/alexjustesen/speedtest-tracker · Image docs: https://docs.linuxserver.io/images/docker-speedtest-tracker/ · App docs: https://docs.speedtest-tracker.dev
- Marketplace: https://railway.com/deploy/speedtest-template
