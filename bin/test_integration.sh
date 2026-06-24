#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "__run" ]]; then
  read -r DB_HOST DB_PORT < <(elixir -e '
uri = URI.parse(System.fetch_env!("DATABASE_URL"))
host = uri.host || "localhost"
port = uri.port || 5432
IO.puts("#{host} #{port}")
')

  until nc -z "$DB_HOST" "$DB_PORT" >/dev/null 2>&1; do
    sleep 0.2
  done

  exec mix test test/integration
fi

if [[ -z "${DOCKER_HOST:-}" ]]; then
  if [[ -S "$HOME/.rd/docker.sock" ]]; then
    export DOCKER_HOST="unix://$HOME/.rd/docker.sock"
  elif [[ -S "$HOME/.docker/run/docker.sock" ]]; then
    export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
  elif [[ -S "/var/run/docker.sock" ]]; then
    export DOCKER_HOST="unix:///var/run/docker.sock"
  fi
fi

if [[ "$(uname -s)" == "Darwin" && -z "${TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE:-}" ]]; then
  export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="/var/run/docker.sock"
fi

exec env MIX_ENV=test mix testcontainers.run cmd -- ./bin/test_integration.sh __run
