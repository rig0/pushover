# Pushover CLI

Tiny Bash helper for sending Pushover notifications with every parameter supported.


## What it does
- Sends a Pushover message with a single argument or `key=value` pairs
- Supports all parameters (attachments, emergency priority, callbacks, etc.)
- Uses defaults for app token, user token, title, sound, and URL set by the installer

## Prereqs
- Pushover account with a User Key
- API Token/Key for your application
- `curl` available on the system

## Install
From the project directory:
```bash
chmod +x install-pushover.sh
sudo ./install-pushover.sh title="My App" user=USERKEY token=APPKEY sound=bell url=https://example.com
```
This writes the configured script to `/usr/bin/pushover` and marks it executable.

## Quick start
```bash
pushover "Backup completed"
pushover message="user@server logged in" title="Login Alert" sound=siren device=phone
```

## Full usage
Every Pushover parameter is supported; all are optional except `message`.
```bash
pushover message="..." \
         title="..." \
         user=USER_KEY \
         token=APP_TOKEN \
         device=phone \
         url=https://example.com \
         url_title="View status" \
         priority=1 \
         timestamp=1715555555 \
         sound=magic \
         html=1 \
         monospace=1 \
         callback=https://callback.example.com \
         retry=60 \
         expire=3600 \
         ttl=3600 \
         attachment=/path/to/file.png
```

### Parameter aliases
- `token` aliases: `app`, `appkey`, `apptoken`
- `user` aliases: `userkey`
- `message` alias: `msg`
- `url_title` alias: `urltitle`

### Priority notes
- `priority=2` (emergency) requires `retry` and `expire`
- `ttl` is optional and applies to all priorities

### Attachments
- Use `attachment=/path/to/file`
- Or `attachment_base64=...` with optional `attachment_type=image/png`
- Only one attachment method at a time

### Defaults
`install-pushover.sh` sets:
- `token` (app key)
- `user` (user key)
- `title` (app title)
- Optional `sound` and `url`

## Troubleshooting
- Missing defaults: rerun the installer or pass `user=` and `token=`
- Priority errors: ensure `retry` and `expire` with `priority=2`
- Attachment errors: check the file path and permissions

## Uninstall
Remove the installed wrapper:
```bash
sudo rm -f /usr/bin/pushover
```
