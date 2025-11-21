#!/usr/bin/env bash

# Pushover installation script by Rigo Sotomayor

set -euo pipefail

show_help() {
  cat <<'EOF'
Usage:
  install-pushover.sh title="My App" user=USERKEY token=APPKEY sound=bell url=https://example.com
EOF
}

normalize_key() {
  local key="${1,,}"
  key="${key//-/_}"
  case "$key" in
    app|appkey|apptoken|token) echo "token" ;;
    user|userkey) echo "user" ;;
    title|sound|url) echo "$key" ;;
    *) echo "" ;;
  esac
}

TITLE=""
USERKEY=""
APPKEY=""
SOUND=""
URL=""

if [[ $# -eq 0 ]]; then
  show_help
  exit 1
fi

for arg in "$@"; do
  if [[ "$arg" != *=* ]]; then
    echo "Unrecognized argument: $arg" >&2
    show_help
    exit 1
  fi
  raw_key=${arg%%=*}
  val=${arg#*=}
  key=$(normalize_key "$raw_key")
  case "$key" in
    title) TITLE="$val" ;;
    user) USERKEY="$val" ;;
    token) APPKEY="$val" ;;
    sound) SOUND="$val" ;;
    url) URL="$val" ;;
    *)
      echo "Unsupported parameter: $raw_key" >&2
      show_help
      exit 1
      ;;
  esac
done

if [[ -z "$TITLE" || -z "$USERKEY" || -z "$APPKEY" ]]; then
  echo "Error: title, user, and token/appkey are required." >&2
  show_help
  exit 1
fi

BASEDIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT="$BASEDIR/pushover.sh"

sed -i "s/USER_TOKEN=.*/USER_TOKEN=\"$USERKEY\"/g" "$SCRIPT"
sed -i "s/DEFAULT_APP=.*/DEFAULT_APP=\"$APPKEY\"/g" "$SCRIPT"
sed -i "s/DEFAULT_SOUND=.*/DEFAULT_SOUND=\"$SOUND\"/g" "$SCRIPT"
sed -i "s+DEFAULT_URL=.*+DEFAULT_URL=\"$URL\"+g" "$SCRIPT" # use + delimiter for URLs
sed -i "s/DEFAULT_TITLE=.*/DEFAULT_TITLE=\"$TITLE\"/g" "$SCRIPT"

cp "$SCRIPT" /usr/bin/pushover
chmod +x /usr/bin/pushover

pushover "Pushover Successfully Installed" title="$TITLE"
