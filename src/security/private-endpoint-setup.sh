#!/usr/bin/env bash
# Disables public network access and creates a Private Endpoint so the
# server is only reachable from inside the given VNet/subnet.
#
# Usage: ./private-endpoint-setup.sh <resource-group> <server-name> <vnet-name> <subnet-name>
set -euo pipefail

RESOURCE_GROUP="${1:?Usage: $0 <resource-group> <server-name> <vnet-name> <subnet-name>}"
SERVER_NAME="${2:?}"
VNET_NAME="${3:?}"
SUBNET_NAME="${4:?}"

echo "Disabling public network access on $SERVER_NAME..."
az postgres flexible-server update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --public-access Disabled

SERVER_ID=$(az postgres flexible-server show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --query id -o tsv)

echo "Creating private endpoint..."
az network private-endpoint create \
  --resource-group "$RESOURCE_GROUP" \
  --name "pe-${SERVER_NAME}" \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME" \
  --private-connection-resource-id "$SERVER_ID" \
  --group-id postgresqlServer \
  --connection-name "${SERVER_NAME}-connection"

echo "Done. $SERVER_NAME is now only reachable from inside $VNET_NAME/$SUBNET_NAME."
