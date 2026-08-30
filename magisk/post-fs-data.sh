#!/system/bin/sh
MODDIR=${0%/*}
LOG=/data/local/tmp/qp_refresh120.log
KO=$MODDIR/qp_refresh120.ko
CONN=/sys/class/drm/card0-DSI-1/status
MODES=/sys/class/drm/card0-DSI-1/modes
MARK=/dev/qp120_patched

{
  if grep -q '^qp_refresh120 ' /proc/modules 2>/dev/null; then
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
    grep -q 'x120x' "$MODES" 2>/dev/null && { echo "120 present after ${i}00ms"; break; }
    i=$((i+1)); usleep 100000 2>/dev/null || sleep 1
  done
  cat "$MODES" 2>/dev/null
  : > "$MARK" 2>/dev/null
} >> "$LOG" 2>&1
