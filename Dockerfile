FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY _build/prod/rel/daily_logos/*.tar.gz .

RUN tar -xzf *.tar.gz && rm *.tar.gz

RUN useradd -m -u 1000 app && chown -R app:app /app
USER app

EXPOSE 4000

ENV PHX_SERVER=true

CMD ["bin/daily_logos", "start"]

