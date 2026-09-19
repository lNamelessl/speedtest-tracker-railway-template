# Speedtest Tracker (continuous internet-speed monitoring) on Railway.
#
# Pinned to linuxserver.io's build of speedtest-tracker v1.15.0
# (lscr.io/linuxserver/speedtest-tracker:1.15.0 == release tag v1.15.0-ls171;
# "latest" is the moving tag - 1.15.0 is the pinned snapshot this template is
# verified on).
FROM lscr.io/linuxserver/speedtest-tracker:1.15.0

# Boot wrapper that generates + persists the mandatory Laravel APP_KEY on a
# fresh volume (upstream halts the container without one). See the script.
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 755 /usr/local/bin/railway-entrypoint.sh

# Upstream image facts (verified from linuxserver/docker-speedtest-tracker @ 1.15.0):
#   ENTRYPOINT ["/init"] (s6-overlay v3); VOLUME /config; web UI on port 80
#   (HTTP - the Railway edge adds TLS). SQLite DB lives at /config/database.sqlite
#   (symlinked into /app/www/database/), Laravel log at /config/log/laravel.log,
#   everything else app-side persists under /config too. Scheduled tests run via
#   a container crontab hitting `artisan schedule:run` every minute, which reads
#   SPEEDTEST_SCHEDULE from the environment - no extra cron service needed.

# Sensible defaults baked into the image so the template deploys with zero
# form prompts. Every value can be overridden on Railway by adding a service
# variable with the same name (Variables tab) and redeploying.
ENV PUID=1000 \
    PGID=1000 \
    TZ=Etc/UTC \
    DB_CONNECTION=sqlite \
    SPEEDTEST_SCHEDULE="0 */6 * * *" \
    PRUNE_RESULTS_OLDER_THAN=0

# The APP_KEY is NOT here on purpose: it is generated per deploy (fresh random
# 32-byte key) by the wrapper and persisted on the /config volume. See the
# README before ever setting/rotating it manually.
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
