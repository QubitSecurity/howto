#!/usr/bin/env bash
# Install/upgrade only. Does not change rsyslog/HAProxy, restart services, open
# firewall ports, disable SELinux, or delete queued messages.
set -euo pipefail
cd "$(dirname "$0")/.."
replace=0
if [[ ${1:-} == --replace-config && $# == 1 ]]; then replace=1
elif (($#));then echo "Usage: $0 [--replace-config]" >&2;exit 2;fi
root=${DESTDIR:-}
[[ -z $root || $root == /* ]] || { echo 'DESTDIR must be absolute' >&2;exit 2; }
if [[ -z $root && $EUID -ne 0 ]];then echo 'Run as root (or sudo).' >&2;exit 2;fi
exe=bin/plura-syslog-sender
[[ -x $exe ]] || { echo 'Run bash scripts/build.sh first.' >&2;exit 2; }
[[ $("$exe" -version) == 0.5.0 ]] || { echo 'Expected v0.5.0 binary.' >&2;exit 2; }
etc="$root/etc/plura-syslog"
sender=conf/sender.json
health=conf/health.json
[[ $replace == 1 || ! -f $etc/sender.json ]] || sender="$etc/sender.json"
[[ $replace == 1 || ! -f $etc/health.json ]] || health="$etc/health.json"
# Validate BEFORE any writes. Placeholders/mismatched HA addresses fail closed.
"$exe" -config "$sender" -check-config
"$exe" -health -config "$health" -check-config
"$exe" -config "$sender" -check-pair "$health"
if [[ -z $root ]];then
  echo 'Install only: stop/replace services later during the explicit cutover.'
fi
stamp=$(date +%Y%m%d-%H%M%S)-$$
backup="$root/var/backups/plura-syslog/$stamp"
install -d -m 0700 "$backup"
install -d -m 0755 "$root/usr/libexec/rsyslog" "$root/etc/systemd/system" "$root/etc/logrotate.d"
install -d -m 0750 "$etc" "$root/var/log/plura" "$root/run/plura-syslog"
# Updating a running executable via direct cp can fail with ETXTBSY. Rename a
# fully written new inode instead. Existing processes stay old until restart.
atomic_install() {
  local src=$1 dst=$2 mode=$3 tmp
  if [[ -L $dst ]];then echo "Refusing symlink destination: $dst" >&2;return 2;fi
  if [[ -e $dst ]];then cp -a -- "$dst" "$backup/$(basename "$dst")";fi
  tmp=$(mktemp "${dst}.new.XXXXXX")
  if ! install -m "$mode" -- "$src" "$tmp";then rm -f -- "$tmp";return 1;fi
  mv -fT -- "$tmp" "$dst"
}
if [[ $sender != "$etc/sender.json" ]];then atomic_install "$sender" "$etc/sender.json" 0640;fi
if [[ $health != "$etc/health.json" ]];then atomic_install "$health" "$etc/health.json" 0640;fi
atomic_install "$exe" "$root/usr/libexec/rsyslog/plura-syslog-sender" 0755
atomic_install conf/plura-syslog-health.service "$root/etc/systemd/system/plura-syslog-health.service" 0644
# Keep an existing log rotation policy; admins may have customized retention.
if [[ ! -e $root/etc/logrotate.d/plura-syslog ]];then
  atomic_install conf/plura-syslog.logrotate "$root/etc/logrotate.d/plura-syslog" 0644
fi
if [[ -z $root ]] && command -v restorecon >/dev/null 2>&1;then
  restorecon -RF /usr/libexec/rsyslog/plura-syslog-sender /etc/plura-syslog /var/log/plura /etc/systemd/system/plura-syslog-health.service || {
    echo 'WARNING: inspect SELinux labels before starting services.' >&2
  }
fi
printf 'Installed Go Sender 0.5.0. Backups: %s\n' "$backup"
printf 'Existing valid sender.json / health.json preserved unless --replace-config was given.\n'
printf 'rsyslog.conf and HAProxy config NOT changed. Services NOT restarted.\n'
printf 'Next: rsyslogd -N1; planned drain/cutover; daemon-reload; restart rsyslog and health.\n'
