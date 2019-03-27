#!/bin/sh
DIR=${1:-.}
PASSWORD="a"

find "$DIR" -name '*.kdbx' | while read DB_FILE; do
  DB_FILE_OLD="$DB_FILE.old"
  DB_FILE_NEW="$DB_FILE.new"
  DB_KEY="$(echo "$DB_FILE" | sed 's/.kdbx$/.key/')"
  DB_KEY_OLD="$DB_KEY.old"
  DB_KEY_NEW="$DB_KEY.new"

  echo "Processing: $DB_FILE"
  if [ ! -f "$DB_KEY" ]; then
    echo "Error: key file not found: $DB_KEY"
    break
  fi

  echo "Checking database connection: $DB_FILE"
  if ! yes "$PASSWORD" | keepassxc-cli ls "$DB_FILE" -qk "$DB_KEY" >/dev/null; then
    break
  fi

  echo "Generating new key: $DB_KEY_NEW"
  if [ -f "$DB_KEY_NEW" ]; then
    echo "File $DB_KEY_NEW already exists."
    break
  fi
  dd if=/dev/urandom count=1 bs=1M of="$DB_KEY_NEW" 2>/dev/null

  echo "Creating new database: $DB_FILE"
  yes "$PASSWORD" | keepassxc-cli create "$DB_FILE_NEW" -k "$DB_KEY_NEW" >/dev/null
  
  echo "Merging $DB_FILE to $DB_FILE_NEW"
  yes "$PASSWORD" | keepassxc-cli merge "$DB_FILE_NEW" "$DB_FILE" -k "$DB_KEY_NEW" -f "$DB_KEY" -q

  echo "Swap database: $DB_FILE"
  mv "$DB_FILE" "$DB_FILE_OLD"
  mv "$DB_KEY" "$DB_KEY_OLD"
  mv "$DB_FILE_NEW" "$DB_FILE"
  mv "$DB_KEY_NEW" "$DB_KEY"
done
