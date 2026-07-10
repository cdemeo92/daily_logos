FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY _build/prod/rel/daily_logos .

RUN chown -R ubuntu:ubuntu /app
USER ubuntu

EXPOSE 4000

ENV PHX_SERVER=true

CMD ["bin/daily_logos", "start"]

