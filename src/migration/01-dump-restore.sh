#!/usr/bin/env bash
# Simple migration path: pg_dump / pg_restore.
# Downtime is proportional to database size — acceptable when a
# maintenance window is fine. For near-zero downtime, use
# 02-logical-replication.sh instead.
#
# Usage: ./01-dump-restore.sh <source-host> <target-host> <database-name>
set -euo pipefail

SOURCE_HOST="${1:?Usage: $0 <source-host> <target-host> <database-name>}"
TARGET_HOST="${2:?Usage: $0 <source-host> <target-host> <database-name>}"
DB_NAME="${3:?Usage: $0 <source-host> <target-host> <database-name>}"
DUMP_FILE="${DB_NAME}.dump"

echo "=== Dumping $DB_NAME from $SOURCE_HOST ==="
pg_dump -h "$SOURCE_HOST" -U dbadmin -d "$DB_NAME" -Fc -f "$DUMP_FILE"

echo "=== Restoring $DB_NAME to $TARGET_HOST ==="
# --no-owner --no-acl: strip role/permission definitions that likely
# don't exist identically on the target; set them explicitly afterward
# instead of letting the restore fail on a missing role.
pg_restore -h "$TARGET_HOST" -U dbadmin -d "$DB_NAME" --no-owner --no-acl -j 4 "$DUMP_FILE"

echo "Done. Verify row counts on both sides before cutting over the application."
