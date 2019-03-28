#!/bin/sh
DB_FILE="$1"
DB_FILE_OLD="${DB_FILE_OLD:-$(dirname "$DB_FILE")/.$(basename "$DB_FILE").old}"
DB_FILE_NEW="${DB_FILE_NEW:-$(dirname "$DB_FILE")/.$(basename "$DB_FILE").new}"
DB_KEY="${DB_KEY:-$(dirname "$DB_FILE")/$(basename "$DB_FILE" .kdbx).key}"
DB_KEY_OLD="${DB_KEY_OLD:-$(dirname "$DB_KEY")/.$(basename "$DB_KEY").old}"
DB_KEY_NEW="${DB_KEY_NEW:-$(dirname "$DB_KEY")/.$(basename "$DB_KEY").new}"
DB_PASSWORD_FILE="${DB_PASSWORD_FILE:-$(dirname "$DB_FILE")/.$(basename "$DB_FILE" .kdbx).password}"

if [ -z "$1" ]; then
  echo "Error: database is not specified."
  exit 1
fi

if [ "${DB_FILE##*.}" != "kdbx" ]; then
  echo "Error: database file not in kdbx format: $DB_FILE"
  exit 2
fi

if [ ! -f "$DB_FILE" ]; then
  echo "Error: database file not exists: $DB_FILE"
  exit 3
fi

echo "Processing: $DB_FILE"

if [ ! -f "$DB_PASSWORD_FILE" ]; then
  echo "Error: password file not found: $DB_PASSWORD_FILE"
  exit 4
fi

if [ ! -f "$DB_KEY" ]; then
  echo "Error: key file not found: $DB_KEY"
  exit 5
fi

echo "Checking database connection: $DB_FILE"
cat "$DB_PASSWORD_FILE" | keepassxc-cli ls "$DB_FILE" -qk "$DB_KEY" >/dev/null || exit 4

# Check for old files
if [ "$OVERWRITE_OLD" != "1" ]; then
  if [ -f "$DB_FILE_OLD" ]; then
    echo "File $DB_FILE_OLD already exists."
    exit 6
  fi
  if [ -f "$DB_KEY_OLD" ]; then
    echo "File $DB_KEY_OLD already exists."
    exit 6
  fi
fi

echo "Generating new key: $DB_KEY_NEW"
if [ -f "$DB_KEY_NEW" ]; then
  echo "File $DB_KEY_NEW already exists."
  exit 7
fi
dd if=/dev/urandom count=1 bs=1M of="$DB_KEY_NEW" 2>/dev/null

echo "Creating new database: $DB_FILE"
cat "$DB_PASSWORD_FILE" | keepassxc-cli create "$DB_FILE_NEW" -k "$DB_KEY_NEW" >/dev/null || exit 7

echo "Merging $DB_FILE to $DB_FILE_NEW"
while :; do cat "$DB_PASSWORD_FILE" || break; done | keepassxc-cli merge "$DB_FILE_NEW" "$DB_FILE" -k "$DB_KEY_NEW" -f "$DB_KEY" -q || exit 8

echo "Swap database: $DB_FILE"
mv "$DB_FILE" "$DB_FILE_OLD"
mv "$DB_KEY" "$DB_KEY_OLD"
mv "$DB_FILE_NEW" "$DB_FILE"
mv "$DB_KEY_NEW" "$DB_KEY"
