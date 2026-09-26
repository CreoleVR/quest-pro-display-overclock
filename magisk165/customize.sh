if [ -d /data/adb/modules/qp_refresh120 ] && [ ! -e /data/adb/modules/qp_refresh120/disable ]; then
  touch /data/adb/modules/qp_refresh120/disable
  ui_print "- disabled qp_refresh120 (this module replaces it)"
fi
