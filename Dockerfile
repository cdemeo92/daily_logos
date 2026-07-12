FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY _build/prod/rel/daily_logos .

RUN chown -R ubuntu:ubuntu /app && \
    chmod -R +x /app

USER ubuntu

EXPOSE 4000

ENV PHX_SERVER=true

CMD ["sh", "-c", "set -e; bin/daily_logos eval 'DailyLogos.Release.migrate'; exec bin/daily_logos start"]

