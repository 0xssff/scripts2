#!/system/bin/sh

JOTTERPAD_DIR='/sdcard/JotterPadX'
JOTTERPAD_BACKUP="$HOME/jotterpad.tar.gz"
[ ! -d "$JOTTERPAD_DIR" ] && exit 0

echo "-------------------------------"
echo "Backing up JotterPad directory!"
echo ""

echo "Getting last backup date..."
echo ""
BACKUP_DATE=$()

# Skip directory backup if backup recent, else, backup!
NOW=$(date +%s)
BACKUP_TIME=$(date -r "$JOTTERPAD_BACKUP" +%s)
let TIME_DIFF="$NOW - $BACKUP_TIME"
if [ $TIME_DIFF -lt 3600 ]; then
    echo "Skipping! Backup performed at: $(date -r "$JOTTERPAD_BACKUP" "+%T on %F")"
else
    TMP_DIR=$(mktemp -d)
    CUR_DIR=$(pwd)
    cd "$JOTTERPAD_DIR/.."

    echo "Tar'ing directory..."
    tar -czvf "$TMP_DIR/jotterpad.tar.gz" JotterPadX/*

    echo ""
    echo "Copying to home directory..."
    cp "$TMP_DIR/jotterpad.tar.gz" "$JOTTERPAD_BACKUP"

    cd "$CUR_DIR"
    rm -rf "$TMP_DIR"
    unset TMP_DIR CUR_DIR
fi

unset JOTTERPAD_DIR JOTTERPAD_BACKUP NOW BACKUP_TIME TIME_DIFF

echo ""
echo "Done!"
echo "-------------------------------"
