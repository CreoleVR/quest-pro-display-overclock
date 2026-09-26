#!/system/bin/sh
MODDIR=${0%/*}
LOG=$MODDIR/post-fs-data.log
KO=$MODDIR/qp_refresh165.ko
CONN=/sys/class/drm/card0-DSI-1/status
MODES=/sys/class/drm/card0-DSI-1/modes
MARK=/dev/qp165_patched

{
  if grep -q '^qp_refresh120 ' /proc/modules 2>/dev/null; then
    echo "qp_refresh120 is loaded (disable it in magisk); not patching"; exit 0
  elif grep -q '^qp_refresh165 ' /proc/modules 2>/dev/null; then
    echo "module already loaded"
  else
    OLD_KPTR=$(cat /proc/sys/kernel/kptr_restrict 2>/dev/null)
    echo 0 > /proc/sys/kernel/kptr_restrict 2>/dev/null
    ADDR=$(grep -m1 ' dsi_display_get_active_displays$' /proc/kallsyms | awk '{print $1}')
    [ -n "$OLD_KPTR" ] && echo "$OLD_KPTR" > /proc/sys/kernel/kptr_restrict 2>/dev/null
    if [ -z "$ADDR" ] || [ "$ADDR" = "0000000000000000" ]; then
      echo "failed to resolve dsi_display_get_active_displays; aborting"; exit 0
    fi
    while [ ${#ADDR} -lt 16 ]; do ADDR=0$ADDR; done
    HI=$(printf %u "0x$(echo "$ADDR" | cut -c1-8)")
    LO=$(printf %u "0x$(echo "$ADDR" | cut -c9-16)")
    insmod "$KO" get_disp_hi=$HI get_disp_lo=$LO
    echo "insmod rc=$?"
  fi

  [ -e "$CONN" ] && echo detect > "$CONN" 2>/dev/null
  i=0
  while [ $i -lt 30 ]; do
    grep -q 'x165x' "$MODES" 2>/dev/null && { echo "165 present after ${i}00ms"; break; }
    i=$((i+1)); usleep 100000 2>/dev/null || sleep 1
  done
  cat "$MODES" 2>/dev/null
  : > "$MARK" 2>/dev/null

  CONF=$MODDIR/qp165.conf
  PENDING=$MODDIR/direct_pending
  FAILED=$MODDIR/direct_failed
  conf(){ sed -n "s/^$1=//p" "$CONF" 2>/dev/null | tail -1; }
  if [ "$(conf direct)" != 1 ]; then
    echo "direct mode off in qp165.conf"
  elif [ -e "$FAILED" ]; then
    echo "direct mode off: an earlier direct-mode boot never finished (delete $FAILED to retry)"
  elif [ -e "$PENDING" ]; then
    mv "$PENDING" "$FAILED"
    echo "direct mode off: the last direct-mode boot never finished (delete $FAILED to retry)"
  elif ! grep -q 'x165x' "$MODES" 2>/dev/null; then
    echo "direct mode off: no 144/165 Hz modes"
  else
    : > "$PENDING"
    resetprop ro.vros.composer.cac_mode direct
    echo "direct mode on"
  fi
} > "$LOG" 2>&1
