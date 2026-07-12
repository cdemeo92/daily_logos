FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libstdc++6 \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY _build/prod/rel/daily_logos .

RUN groupadd --system app && \
    useradd --system --gid app --home-dir /app --shell /usr/sbin/nologin app && \
    chown -R app:app /app && \
    chmod -R +x /app

USER app

EXPOSE 4000

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ERL_AFLAGS=+fnu \
    PHX_SERVER=true

CMD ["sh", "-c", "set -e; bin/daily_logos eval 'DailyLogos.Release.migrate'; exec bin/daily_logos start"]

