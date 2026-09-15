#!/usr/bin/env bash
# Near-zero-downtime migration via logical replication: sync the target
# continuously, then cut over once lag reaches zero.
#
# Prerequisites:
#   - Target schema already created (pg_dump --schema-only | pg_restore)
#   - wal_level = 'logical' set on the source (requires a restart)
#
# Usage: ./02-logical-replication.sh <source-host> <target-host> <database-name>
set -euo pipefail

SOURCE_HOST="${1:?Usage: $0 <source-host> <target-host> <database-name>}"
TARGET_HOST="${2:?Usage: $0 <source-host> <target-host> <database-name>}"
DB_NAME="${3:?Usage: $0 <source-host> <target-host> <database-name>}"

echo "=== Step 1: copy schema only to target (run once) ==="
echo "pg_dump -h $SOURCE_HOST -U dbadmin -d $DB_NAME --schema-only -f schema.sql"
echo "psql -h $TARGET_HOST -U dbadmin -d $DB_NAME -f schema.sql"
echo

echo "=== Step 2: create the publication on the source ==="
psql -h "$SOURCE_HOST" -U dbadmin -d "$DB_NAME" -c \
  "CREATE PUBLICATION migration_pub FOR ALL TABLES;"

echo "=== Step 3: create the subscription on the target ==="
read -r -p "Source connection password for role 'replicator': " -s REPLICATOR_PASSWORD
echo
psql -h "$TARGET_HOST" -U dbadmin -d "$DB_NAME" -c \
  "CREATE SUBSCRIPTION migration_sub CONNECTION 'host=$SOURCE_HOST dbname=$DB_NAME user=replicator password=$REPLICATOR_PASSWORD' PUBLICATION migration_pub;"

echo "=== Step 4: watch replication lag on the source ==="
echo "Run this repeatedly until lag reaches 0 bytes before cutting over:"
echo
echo "  psql -h $SOURCE_HOST -U dbadmin -d $DB_NAME -c \\"
echo "    \"SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS lag FROM pg_replication_slots;\""
echo
echo "Once lag is 0: point the application connection string at $TARGET_HOST,"
echo "verify writes land there, then drop the subscription on the target:"
echo "  psql -h $TARGET_HOST -U dbadmin -d $DB_NAME -c \"DROP SUBSCRIPTION migration_sub;\""
