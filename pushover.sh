#!/usr/bin/env bash

# Pushover script by rig0.
# Usage:
#   pushover "backup complete"
#   pushover message="Server backup complete" title=Hostname priority=-1
#   pushover message="Production server down!" title=Hostname priority=1 sound=siren device=phone
#
# All Pushover parameters are supported and optional except for message.
# Defaults for token, user, title, sound, and url are filled by install-pushover.sh.

set -euo pipefail

USER_TOKEN=
DEFAULT_APP=
DEFAULT_SOUND=
DEFAULT_URL=
DEFAULT_TITLE=

show_help() {
  cat <<'EOF'
Usage:
  pushover "<message text>"
  pushover message="..." title="..." sound=... url=... url_title="..." device=... priority=... timestamp=... html=1 monospace=1 callback=https://... retry=60 expire=3600 ttl=3600 attachment=/path/to/file

Supported parameters:
  token, user, message, device, title, url, url_title, priority, timestamp, sound,
  html, monospace, attachment, attachment_base64, attachment_type, callback, retry,
  expire, ttl
Defaults for token, user, and title (plus sound/url if set) come from install-pushover.sh.
EOF
}

normalize_key() {
  local key="${1,,}"
  key="${key//-/_}"
  case "$key" in
    app|apptoken) echo "token" ;;
    userkey) echo "user" ;;
    msg) echo "message" ;;
    urltitle) echo "url_title" ;;
    *) echo "$key" ;;
  esac
}

is_supported_key() {
  local key="$1"
  case "$key" in
    token|user|message|device|title|url|url_title|priority|timestamp|sound|html|monospace|attachment|attachment_base64|attachment_type|callback|retry|expire|ttl)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

declare -A params=(
  [token]="$DEFAULT_APP"
  [user]="$USER_TOKEN"
  [message]=""
  [device]=""
  [title]="$DEFAULT_TITLE"
  [url]="$DEFAULT_URL"
  [url_title]=""
  [priority]=""
  [timestamp]=""
  [sound]="$DEFAULT_SOUND"
  [html]=""
  [monospace]=""
  [attachment]=""
  [attachment_base64]=""
  [attachment_type]=""
  [callback]=""
  [retry]=""
  [expire]=""
  [ttl]=""
)
declare -A provided

if [[ $# -eq 0 ]]; then
  show_help
  exit 1
fi

if [[ $# -eq 1 && "$1" != *=* ]]; then
  params[message]=$1
else
  for arg in "$@"; do
    if [[ "$arg" == *=* ]]; then
      key=$(normalize_key "${arg%%=*}")
      value=${arg#*=}

      if ! is_supported_key "$key"; then
        echo "Unsupported parameter: ${arg%%=*}" >&2
        show_help
        exit 1
      fi

      params["$key"]="$value"
      provided["$key"]=1
    else
      if [[ -z "${params[message]}" ]]; then
        params[message]="$arg"
      else
        echo "Unrecognized argument: $arg" >&2
        show_help
        exit 1
      fi
    fi
  done
fi

if [[ -z "${params[message]}" ]]; then
  echo "Error: message is required (use pushover \"text\" or message=\"text\")." >&2
  exit 1
fi

if [[ -z "${params[token]}" ]]; then
  echo "Error: app token is not set. Provide token=... or rerun install-pushover.sh." >&2
  exit 1
fi

if [[ -z "${params[user]}" ]]; then
  echo "Error: user token is not set. Provide user=... or rerun install-pushover.sh." >&2
  exit 1
fi

if [[ "${params[priority]}" == "2" ]]; then
  if [[ -z "${params[retry]}" || -z "${params[expire]}" ]]; then
    echo "Error: priority=2 requires retry and expire to be set." >&2
    exit 1
  fi
fi

if [[ -n "${params[attachment]}" && -n "${params[attachment_base64]}" ]]; then
  echo "Error: use only one of attachment or attachment_base64." >&2
  exit 1
fi

curl_args=(-sS --fail --show-error)

add_field() {
  local key="$1"
  local value="$2"
  # include if we have a non-empty value or the user explicitly provided it
  if [[ -n "$value" || -n "${provided[$key]:-}" ]]; then
    curl_args+=(--form-string "$key=$value")
  fi
}

add_field "token" "${params[token]}"
add_field "user" "${params[user]}"
add_field "message" "${params[message]}"
add_field "device" "${params[device]}"
add_field "title" "${params[title]}"
add_field "url" "${params[url]}"
add_field "url_title" "${params[url_title]}"
add_field "priority" "${params[priority]}"
add_field "timestamp" "${params[timestamp]}"
add_field "sound" "${params[sound]}"
add_field "html" "${params[html]}"
add_field "monospace" "${params[monospace]}"
add_field "callback" "${params[callback]}"
add_field "retry" "${params[retry]}"
add_field "expire" "${params[expire]}"
add_field "ttl" "${params[ttl]}"

if [[ -n "${params[attachment]}" ]]; then
  if [[ ! -f "${params[attachment]}" ]]; then
    echo "Attachment file not found: ${params[attachment]}" >&2
    exit 1
  fi

  if [[ -n "${params[attachment_type]}" ]]; then
    curl_args+=(--form "attachment=@${params[attachment]};type=${params[attachment_type]}")
  else
    curl_args+=(--form "attachment=@${params[attachment]}")
  fi
elif [[ -n "${params[attachment_base64]}" ]]; then
  curl_args+=(--form-string "attachment_base64=${params[attachment_base64]}")
  add_field "attachment_type" "${params[attachment_type]}"
fi

curl "${curl_args[@]}" https://api.pushover.net/1/messages.json >/dev/null
