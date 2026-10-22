#!/bin/sh
# Writes the session key into the app's data file so the exchanger
# auto-starts it on every boot (no UI interaction needed).
mkdir -p /home/exchanger/data
if [ -n "$SESSION_KEY" ]; then
  printf '["%s"]' "$SESSION_KEY" > /home/exchanger/data/sessions.json
fi
PUB=${PORT:-10000}
APP_PORT=3000 PROXY_PORT=$PUB node /home/exchanger/proxy.js &
node /home/exchanger/keepalive.js &
PORT=3000 exec node src/server.js











