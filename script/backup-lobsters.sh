#!/bin/bash
set -e

TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_DIR="/var/backups/lobsters"
mkdir -p "$BACKUP_DIR"

echo "Starting backup for Lobsters..."
echo "Destination: $BACKUP_DIR"

# Backup Database
echo " Backing up Database..."
SQL_FILE="$BACKUP_DIR/lobsters_$TIMESTAMP.sql"
# docker exec lobsters-db-1 mysqldump --no-tablespaces -u root -plobsters lobsters > "$SQL_FILE"
docker exec lobsters-db-1   mariadb-dump -u root -plobsters --all-databases > "$SQL_FILE"
gzip "$SQL_FILE"
echo " Database backup created: $SQL_FILE.gz"

# Backup Storage
echo " Backing up Storage..."
# Copy from app container path /lobsters/storage to a temp folder, then tar it
STORAGE_ARCHIVE="$BACKUP_DIR/storage_$TIMESTAMP.tar.gz"
# Since docker cp copies the directory, we need to handle paths
TEMP_STORAGE="$BACKUP_DIR/storage_temp_$TIMESTAMP"

# Copy /lobsters/storage from container to host
docker cp lobsters-app-1:/lobsters/storage "$TEMP_STORAGE"
tar -czf "$STORAGE_ARCHIVE" -C "$TEMP_STORAGE" .
rm -rf "$TEMP_STORAGE"
echo " Storage backup created: $STORAGE_ARCHIVE"

# Cleanup old backups (keep last 7 days)
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "lobsters_*.sql.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "storage_*.tar.gz" -mtime +7 -delete

echo "Backup complete!"
ls -lh "$BACKUP_DIR"
