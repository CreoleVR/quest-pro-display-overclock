CONF=${0%/*}/qp165.conf
T=/sys/class/drm/card0/sde-crtc-0/vsync_timing
conf() { sed -n "s/^$1=//p" "$CONF" 2>/dev/null | tail -1; }
delay() {
  d=$(conf delay$1)
  [ -n "$d" ] && { echo $d; return; }
  if [ $1 -ge 160 ]; then echo 50
  elif [ $1 -ge 140 ]; then echo 45
  elif [ $1 -ge 115 ]; then echo 35
  elif [ $1 -ge 105 ]; then echo 25
  else echo 0; fi
}
last=
while :; do
  hz=$(sed -n 's/.*@//p' $T 2>/dev/null)
  if [ -n "$hz" ] && [ "$hz" != "$last" ]; then
    setprop debug.oculus.sliceDelay $(delay $hz)
    last=$hz
  fi
  sleep 0.5
done
