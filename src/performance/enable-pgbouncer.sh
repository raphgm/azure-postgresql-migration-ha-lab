#!/usr/bin/env bash
# Enables the built-in PgBouncer connection pooler on a Flexible Server.
# Prefer this over letting an application open a raw connection per
# request — PostgreSQL's per-connection memory overhead makes a large
# number of idle connections expensive.
#
# Usage: ./enable-pgbouncer.sh <resource-group> <server-name>
set -euo pipefail

RESOURCE_GROUP="${1:?Usage: $0 <resource-group> <server-name>}"
SERVER_NAME="${2:?Usage: $0 <resource-group> <server-name>}"

az postgres flexible-server parameter set \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$SERVER_NAME" \
  --name pgbouncer.enabled \
  --value true

echo "PgBouncer enabled on $SERVER_NAME. Connect through the pooled port (6432) for pooled connections."
