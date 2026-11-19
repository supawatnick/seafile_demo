#!/usr/bin/env bash
set -euo pipefail

[[ $EUID == 0 ]] || { echo 'Run this step with sudo.' >&2; exit 1; }
export_path=10.10.10.203:/seafile_01
target=/opt/seafile-data

if ! mountpoint -q "$target"; then
  install -d -m 0755 "$target"
  if [[ -n $(find "$target" -mindepth 1 -maxdepth 1 -print -quit) ]]; then
    echo "Refusing to hide existing files under $target." >&2
    exit 1
  fi
  mount -t nfs -o vers=4.1,hard "$export_path" "$target"
fi

[[ $(findmnt -rn --mountpoint "$target" -t nfs,nfs4 -o SOURCE) == "$export_path" ]] ||
  { echo "Expected $export_path mounted at $target." >&2; exit 1; }

test_file=$(mktemp "$target/.seafile-write-test.XXXXXX")
rm -- "$test_file"
findmnt --mountpoint "$target" -o SOURCE,TARGET,FSTYPE,OPTIONS
echo 'NFS create/delete test passed.'
