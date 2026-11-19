#!/usr/bin/env bash
set -euo pipefail

[[ $EUID == 0 ]] || { echo 'Run this step with sudo.' >&2; exit 1; }
. /etc/os-release
[[ $ID == ubuntu && $VERSION_ID == 24.04 ]] ||
  { echo 'This script targets Ubuntu 24.04.' >&2; exit 1; }

apt-get update
apt-get install -y ca-certificates curl nfs-common openssl
if ! command -v docker >/dev/null; then
  apt-get install -y docker.io docker-compose-v2
fi
docker compose version
docker info >/dev/null
