#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PID_FILE="$ROOT_DIR/.local-server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "No local server pid file found."
  exit 0
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  echo "Stopped Dien Chan App local server."
else
  echo "Local server process is not running."
fi

rm -f "$PID_FILE"
