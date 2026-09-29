# Quest Pro Display Overclock

magisk modules that unlock higher refresh rates on the meta quest pro (seacliff).

| module | rates |
|---|---|
| `qp_refresh120` | 100, 110, 120 hz |
| `qp_refresh165` | 100, 110, 120, 144, 165, 180 hz |

install one. `qp_refresh165` replaces `qp_refresh120`.

everything is applied in memory at boot; no partition is touched. disable the module and reboot to go back to stock.

## install

1. flash the zip from releases in the magisk app
2. reboot
3. pick the rate in any openxr app

## how 144/165/180 works

meta's default compositor mode can't finish frames fast enough above ~130 hz, so every frame shows twice. `qp_refresh165` switches it to direct mode and delays each frame slice per refresh rate so it doesn't tear.

`qp165.conf` in the module folder:

- `direct=0` keeps meta's default mode (clean up to 120 hz)
- `delay144=45` overrides the slice delay for a rate

## limits

- faint ghosting at 144/165/180 hz from the lcd's response time
- 165/180 hz tear while the quest menu is open (the gpu can't keep up)
- color correction is disabled and will introduce chromatic aberration

## build

```
make -C <kernel_out> M=$PWD/module165 modules
cp module165/qp_refresh165.ko magisk165/
cd magisk165
zip -X -r -9 ../qp_refresh165.zip module.prop customize.sh post-fs-data.sh service.sh slicedelay.sh qp165.conf qp_refresh165.ko META-INF
```

use `module/` and `magisk/` for `qp_refresh120`.

## license

GPL-2.0. see [LICENSE](LICENSE).
