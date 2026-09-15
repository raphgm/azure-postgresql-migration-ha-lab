#!/usr/bin/env bash
# Registers a Microsoft Entra group as the database administrator, so
# application/admin authentication can use Entra tokens instead of a
# static database password.
#
# Usage: ./entra-admin-setup.sh <resource-group> <server-name> <display-name> <entra-object-id>
set -euo pipefail

RESOURCE_GROUP="${1:?Usage: $0 <resource-group> <server-name> <display-name> <entra-object-id>}"
SERVER_NAME="${2:?}"
DISPLAY_NAME="${3:?}"
OBJECT_ID="${4:?}"

az postgres flexible-server microsoft-entra-admin create \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$SERVER_NAME" \
  --display-name "$DISPLAY_NAME" \
  --object-id "$OBJECT_ID" \
  --type Group

az postgres flexible-server update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --microsoft-entra-auth Enabled

echo "Microsoft Entra authentication enabled. '$DISPLAY_NAME' can now connect using an Entra access token."
