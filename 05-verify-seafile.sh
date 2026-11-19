#!/usr/bin/env bash
set -euo pipefail

cd /opt/seafile
findmnt --mountpoint /opt/seafile-data -o SOURCE,TARGET,FSTYPE
docker compose ps
curl --fail --silent --show-error --retry 12 --retry-delay 5 --retry-connrefused --max-time 5 \
  http://10.10.110.69/api2/ping/
printf '\n'

seadoc_response=$(curl --fail --silent --show-error --retry 12 --retry-delay 5 --retry-connrefused --max-time 5 \
  http://10.10.110.69/sdoc-server/)
[[ $seadoc_response == *'Welcome to sdoc-server'* ]] ||
  { echo 'Unexpected response from /sdoc-server/.' >&2; exit 1; }
echo 'SeaDoc responded through Caddy.'
