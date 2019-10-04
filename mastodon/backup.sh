#!/bin/sh

ORIG_DIR="$(pwd)"
HOME_DIR=''
LIVE_DIR="$HOME_DIR/live"
BACKUP_DIR="$HOME_DIR/.backup"
ARCHIV_DIR="$HOME_DIR/archives"

# Ensure environment is set (assuming rbenv installed)
export PATH="$HOME_DIR/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Save us time
toot_ctl() {
  RAILS_ENV=production "$LIVE_DIR/bin/tootctl" "$@"
}

# Clear mastodon cache
cd "$LIVE_DIR"
toot_ctl media remove --days 7
toot_ctl cache clear
cd "$ORIG_DIR"

# Backup to live-parallel backup directory
[ -d "$BACKUP_DIR" ] || mkdir -p "$BACKUP_DIR"
pg_dump -Fc mastodon_production > "$BACKUP_DIR/pg.dump"

rsync --archive --times --update --delete-before "$LIVE_DIR" "$BACKUP_DIR"
#rsync --archive --times --update --delete-before '/etc/nginx' "$BACKUP_DIR"
#rsync --archive --times --update --delete-before '/etc/letsencrypt' "$BACKUP_DIR"

# Compress live-parallel backup directory
[ -d "$ARCHIV_DIR" ] || mkdir -p "$ARCHIV_DIR"
tar --numeric-owner -zcf "$ARCHIV_DIR/backup.tar.gz" "$BACKUP_DIR"
rm -f "$BACKUP_DIR/pg.dump" # to save disk-space