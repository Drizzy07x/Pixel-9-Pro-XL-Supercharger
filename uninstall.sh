#!/system/bin/sh
MODDIR="${0%/*}"
PIDFILE="$MODDIR/dashboard_updater.pid"
LOCKDIR="$MODDIR/.dashboard_updater.lock"

if [ -f "$PIDFILE" ]; then
  pid="$(cat "$PIDFILE" 2>/dev/null)"
  case "$pid" in
    ''|*[!0-9]*) ;;
    *) kill "$pid" 2>/dev/null ;;
  esac
fi

rm -f "$PIDFILE" 2>/dev/null
rm -rf "$LOCKDIR" 2>/dev/null
