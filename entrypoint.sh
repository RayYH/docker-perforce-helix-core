#!/usr/bin/env bash
set -euo pipefail

: "${P4ROOT:?}" "${P4LOG:?}" "${P4PORT:?}" "${P4SERVERID:=master.1}"

mkdir -p "$(dirname "$P4LOG")" "$P4ROOT"
chown -R perforce:root /perforce

if [ ! -f "$P4ROOT/db.counters" ]; then
  echo ">> First run: initializing Perforce db under $P4ROOT"
  /usr/local/sbin/gosu perforce p4d -r "$P4ROOT" -xi
fi

if [ ! -f "$P4ROOT/server.id" ]; then
  echo "$P4SERVERID" > "$P4ROOT/server.id"
  chown perforce:root "$P4ROOT/server.id"
  echo ">> Wrote server.id = $P4SERVERID"
fi

echo ">> Starting p4d on 0.0.0.0:${P4PORT}"
exec /usr/local/sbin/gosu perforce p4d -r "$P4ROOT" -L "$P4LOG" -p "0.0.0.0:$P4PORT"
