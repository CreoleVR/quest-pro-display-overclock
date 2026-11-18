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

## after an os update

after an os update the module can go quiet with no error: a `.ko` is only accepted when its `module_layout` CRC matches the running kernel, so the old build fails `insmod` with `invalid module format` and nothing above 90 hz shows up.

the `.ko` in this tree are for os 2.10 — kernel `4.19.325-cip132-st16-g023a62479ec4`, `module_layout` CRC `0x499d5efd`. one build serves one kernel, so `module.prop`'s `version` names the os it was built for.

without that kernel's sources, copy two fields out of a module that does load on it — any `/vendor/lib/modules/*.ko` will do: the `vermagic` string in `.modinfo`, and the 8-byte CRC of the `module_layout` entry in `__versions` (entries are 64 bytes: little-endian CRC, then the symbol name). 18 bytes, file size unchanged. if the version string doesn't fit there, change the CRC alone — with CRCs present the kernel ignores the version in `vermagic`.

`insmod qp_refresh120.ko dry_run=1` prints what the module reads without changing anything. if it still reports `type=4 min=72 max=90 list_len=19`, copying is enough. if not, the driver's structs moved and you need a rebuild from `module/` (which has no `dry_run` as checked in — rebuild and you lose it).

## license

GPL-2.0. see [LICENSE](LICENSE).
