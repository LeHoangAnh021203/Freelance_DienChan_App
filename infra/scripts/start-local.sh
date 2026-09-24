#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WEB_DIR="$ROOT_DIR/mobile/web"
PID_FILE="$ROOT_DIR/.local-server.pid"
PORT="${MOBILE_PORT:-5173}"
HOST="${MOBILE_HOST:-127.0.0.1}"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Dien Chan App is already running at http://$HOST:$PORT"
  exit 0
fi

cd "$ROOT_DIR"
nohup env PORT="$PORT" HOST="$HOST" node backend/server.js >/tmp/dien-chan-app.log 2>&1 &
echo "$!" > "$PID_FILE"
sleep 1

if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  rm -f "$PID_FILE"
  echo "Failed to start Dien Chan App. See /tmp/dien-chan-app.log"
  exit 1
fi

echo "Dien Chan App running at http://$HOST:$PORT"
echo "Log: /tmp/dien-chan-app.log"
