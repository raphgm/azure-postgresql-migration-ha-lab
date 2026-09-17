#!/usr/bin/env bash
# Times a real forced failover on an Azure Database for PostgreSQL Flexible
# Server, matching the measured-RTO discipline in the Alibaba DR lab
# (src/experiments/measure-rto.sh there) instead of just quoting the CLI
# command in prose.
#
# Usage: ./measure-failover-rto.sh <resource-group> <server-name>
set -euo pipefail

RESOURCE_GROUP="${1:?Usage: $0 <resource-group> <server-name>}"
SERVER_NAME="${2:?Usage: $0 <resource-group> <server-name>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_FILE="${SCRIPT_DIR}/../results/failover-rto-results-$(date +%F).csv"
mkdir -p "$(dirname "$RESULTS_FILE")"
[ -f "$RESULTS_FILE" ] || echo "timestamp,resource_group,server_name,rto_seconds" > "$RESULTS_FILE"

echo "Triggering forced failover on $SERVER_NAME (resource group: $RESOURCE_GROUP)..."
START=$(date +%s)

az postgres flexible-server restart \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --failover Forced

# `az ... restart --failover` returns once the failover operation is
# accepted, not once the server is actually reachable again — the real
# recovery time is measured by polling until the server responds, not by
# trusting the CLI call's own return.
echo "Failover accepted. Polling server state until it's back to Ready..."
while true; do
  STATE=$(az postgres flexible-server show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$SERVER_NAME" \
    --query "state" -o tsv)
  [ "$STATE" == "Ready" ] && break
  sleep 2
done

END=$(date +%s)
RTO=$((END - START))

echo "RTO: ${RTO}"
echo "$(date -u +%FT%TZ),${RESOURCE_GROUP},${SERVER_NAME},${RTO}" >> "$RESULTS_FILE"
echo "Recorded to $RESULTS_FILE"
