#!/usr/bin/env bash
set -euo pipefail
umask 077

[[ $EUID == 0 ]] || { echo 'Run this step with sudo.' >&2; exit 1; }
read -r -p 'Initial admin email: ' admin_email
[[ $admin_email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] ||
  { echo 'Enter a valid email address.' >&2; exit 1; }

target=/opt/seafile
[[ ! -e $target && ! -L $target ]] ||
  { echo "$target already exists. Review its configuration before continuing." >&2; exit 1; }

base=https://manual.seafile.com/14.0/repo/docker
stage=$(mktemp -d /opt/.seafile-setup.XXXXXX)
trap 'rm -rf -- "$stage"' EXIT
curl --fail --silent --show-error --location "$base/ce/env" -o "$stage/.env"
curl --fail --silent --show-error --location "$base/ce/seafile-server.yml" -o "$stage/seafile-server.yml"
curl --fail --silent --show-error --location "$base/caddy.yml" -o "$stage/caddy.yml"
curl --fail --silent --show-error --location "$base/seadoc.yml" -o "$stage/seadoc.yml"

# Remove upstream defaults for the values this installation sets.
sed -i -E '/^(COMPOSE_FILE|COMPOSE_PATH_SEPARATOR|SEAFILE_VOLUME|SEAFILE_MYSQL_VOLUME|SEAFILE_SERVER_HOSTNAME|SEAFILE_SERVER_PROTOCOL|TIME_ZONE|ENABLE_SEADOC|INIT_SEAFILE_ADMIN_EMAIL|JWT_PRIVATE_KEY|INIT_SEAFILE_MYSQL_ROOT_PASSWORD|SEAFILE_MYSQL_DB_PASSWORD|INIT_SEAFILE_ADMIN_PASSWORD)=/d' "$stage/.env"
{
  printf '\n%s\n' \
    'COMPOSE_FILE=seafile-server.yml,caddy.yml,seadoc.yml,nfs-override.yml' \
    'COMPOSE_PATH_SEPARATOR=,' \
    'SEAFILE_VOLUME=/opt/seafile-data' \
    'SEAFILE_MYSQL_VOLUME=/opt/seafile-mysql/db' \
    'SEAFILE_SERVER_HOSTNAME=10.10.110.69' \
    'SEAFILE_SERVER_PROTOCOL=http' \
    'TIME_ZONE=Asia/Bangkok' \
    'ENABLE_SEADOC=true'
  printf 'INIT_SEAFILE_ADMIN_EMAIL=%s\n' "$admin_email"
  for name in JWT_PRIVATE_KEY INIT_SEAFILE_MYSQL_ROOT_PASSWORD SEAFILE_MYSQL_DB_PASSWORD INIT_SEAFILE_ADMIN_PASSWORD; do
    secret=$(openssl rand -hex 24)
    printf '%s=%s\n' "$name" "$secret"
  done
} >> "$stage/.env"

cat > "$stage/nfs-override.yml" <<'YAML'
services:
  seafile:
    restart: "no"
YAML
(cd "$stage" && docker compose config --quiet)
mv -T --no-clobber -- "$stage" "$target"
[[ ! -d $stage ]] || { echo "$target already exists." >&2; exit 1; }
echo "Compose files prepared at $target."
