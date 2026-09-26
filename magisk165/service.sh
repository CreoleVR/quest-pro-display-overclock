#!/system/bin/sh
MODDIR=${0%/*}
MODES=/sys/class/drm/card0-DSI-1/modes
DONE=/dev/qp165_reinit_done
LOG=$MODDIR/service.log
PENDING=$MODDIR/direct_pending
ts(){ echo "[$(date +%H:%M:%S 2>/dev/null)] $*" >> "$LOG"; }

: > "$LOG"
{
  [ -e "$DONE" ] && exit 0

  i=0
  while [ "$(getprop sys.boot_completed 2>/dev/null)" != 1 ] && [ $i -lt 180 ]; do
    sleep 1; i=$((i+1))
  done
  sleep 15

  last=$(dmesg 2>/dev/null | grep -c 'bad magic'); stable=0; waited=0
  while [ $stable -lt 9 ] && [ $waited -lt 90 ]; do
    sleep 3; waited=$((waited+3))
    now=$(dmesg 2>/dev/null | grep -c 'bad magic')
    if [ "$now" = "$last" ]; then stable=$((stable+3)); else stable=0; fi
    last=$now
  done

  setprop debug.oculus.allRefreshRates 1

  if ! grep -q 'x165x' "$MODES" 2>/dev/null; then
    : > "$DONE"; exit 0
  fi
} >> "$LOG" 2>&1

(
  ts "restart QTI composer"
  setprop ctl.restart vendor.qti.hardware.display.composer
  sleep 4
  ts "restart OVR compositor"
  setprop ctl.restart vendor.oculus.hardware.composer-service
  sleep 5
  : > "$DONE"
  ts "done"

  if [ "$(getprop ro.vros.composer.cac_mode)" = direct ]; then
    nohup sh "$MODDIR/slicedelay.sh" > /dev/null 2>&1 &
    ts "slice delay watcher started"
  fi

  if [ -e "$PENDING" ]; then
    i=0
    while [ -z "$(pidof com.oculus.vrruntimeservice)" ] && [ $i -lt 90 ]; do
      sleep 1; i=$((i+1))
    done
    sleep 20
    if [ -n "$(pidof com.oculus.vrruntimeservice)" ]; then
      rm -f "$PENDING"
      ts "direct mode confirmed (cac_mode $(getprop ro.vros.composer.cac_mode))"
    else
      ts "VR runtime isn't running: the next boot uses writeback"
    fi
  fi
) >> "$LOG" 2>&1 &

exit 0
