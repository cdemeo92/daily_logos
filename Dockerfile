FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libncurses6 \
    libstdc++6 \
    libtinfo6 \
    openssl \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 app && \
    useradd --system --uid 10001 --gid app --home-dir /app --create-home --shell /usr/sbin/nologin app

WORKDIR /app

COPY --chown=app:app _build/prod/rel/daily_logos ./

RUN chmod -R +x /app

USER app

EXPOSE 4000

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ERL_AFLAGS=+fnu \
    PHX_SERVER=true

CMD ["sh", "-c", "set -e; bin/daily_logos eval 'DailyLogos.Release.migrate'; exec bin/daily_logos start"]

