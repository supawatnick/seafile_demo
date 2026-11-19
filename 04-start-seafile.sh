#!/usr/bin/env bash
set -euo pipefail

[[ $EUID == 0 ]] || { echo 'Run this step with sudo.' >&2; exit 1; }
[[ $(findmnt -rn --mountpoint /opt/seafile-data -t nfs,nfs4 -o SOURCE) == '10.10.10.203:/seafile_01' ]] ||
  { echo 'Expected ONTAP NFS mount is missing. Run step 02.' >&2; exit 1; }

cd /opt/seafile
docker compose config --quiet
docker compose up -d
docker compose ps
