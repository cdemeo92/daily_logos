#!/usr/bin/env bash
set -euo pipefail

STATE_DIR=".tmp"
CONTAINERS_FILE="$STATE_DIR/testcontainers_created_ids"
HOST_PORT="55432"
TEST_DB_URL="ecto://test:test@localhost:${HOST_PORT}/test"

list_testcontainers_ids() {
  docker ps -a --format '{{.ID}} {{.Image}}' \
    | awk '$2 == "postgres:15-alpine" || $2 == "testcontainers/ryuk:0.14.0" {print $1}' \
    | sort -u
}

configure_docker_for_testcontainers() {
  if [[ -z "${DOCKER_HOST:-}" ]]; then
    if [[ -S "$HOME/.docker/run/docker.sock" ]]; then
      export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
    elif [[ -S "$HOME/.rd/docker.sock" ]]; then
      export DOCKER_HOST="unix://$HOME/.rd/docker.sock"
    elif [[ -S "/var/run/docker.sock" ]]; then
      export DOCKER_HOST="unix:///var/run/docker.sock"
    fi
  fi

  if [[ "$(uname -s)" == "Darwin" && -z "${TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE:-}" ]]; then
    export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="/var/run/docker.sock"
  fi
}

wait_for_database() {
  until (echo >"/dev/tcp/localhost/${HOST_PORT}") >/dev/null 2>&1; do
    sleep 0.2
  done
}

prepare() {
  mkdir -p "$STATE_DIR"
  configure_docker_for_testcontainers

  before_file="$STATE_DIR/.tc_ids_before"
  after_file="$STATE_DIR/.tc_ids_after"

  list_testcontainers_ids >"$before_file"
  MIX_ENV=test mix testcontainers.run --host-port "$HOST_PORT" cmd -- true
  list_testcontainers_ids >"$after_file"

  comm -13 "$before_file" "$after_file" >"$CONTAINERS_FILE"
  rm -f "$before_file" "$after_file"
}

cleanup() {
  if [[ -f "$CONTAINERS_FILE" ]]; then
    xargs -r docker rm -f <"$CONTAINERS_FILE" >/dev/null 2>&1 || true
    rm -f "$CONTAINERS_FILE"
  fi
}

run_tests() {
  export DATABASE_URL="$TEST_DB_URL"

  wait_for_database

  set +e
  mix test test/integration --color
  exit_code=$?
  set -e

  cleanup
  exit $exit_code
}

if [[ "${1:-}" == "prepare" ]]; then
  prepare
else
  run_tests
fi
