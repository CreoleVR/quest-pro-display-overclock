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

the module can go quiet with no error. the `.ko` is only accepted when its `module_layout` CRC matches the running kernel: on os 2.9 (`4.19.325-cip132-st16-…`) the 2.7 build (`4.19.325-cip128-st12-…`) fails `insmod` with `invalid module format` (rc=8), `post-fs-data.sh` logs that, and `service.sh` then finds no `x120x` in the modes and does nothing.

the `.ko` files in the tree are built for os 2.10: kernel `4.19.325-cip132-st16-g023a62479ec4`, `module_layout` CRC `0x499d5efd`. os 2.9 was the same `cip132-st16` base at `-g429559e91fe8` and CRC `0x5e8de9ec` — two builds of one kernel version want different CRCs, which is why the version string alone tells you nothing.

to load on another kernel, rebuild from `module/` against that kernel's sources. without the sources, copy two fields out of a `.ko` that does load on it — every `/vendor/lib/modules/*.ko` qualifies: the `vermagic` string in `.modinfo`, and the 8-byte CRC of the `module_layout` entry in `__versions` (`__versions` entry stride is 64 bytes: 8-byte little-endian CRC, then the symbol name). 18 bytes, file size unchanged. if the new version string is longer than the old one there is no room in `.modinfo`; change only the CRC — with CRCs present the kernel compares just the flags tail of `vermagic`, not the version.

that patches the gate, not the driver. the shipped `.ko` accepts `dry_run=1`, which prints what it read from the driver without modifying anything: on 2.7, 2.9 and 2.10 that was `type=4 min=72 max=90 list_len=19`, so the struct offsets in `module/qp_refresh120.c` have not needed changing yet. if a future os reports a different shape, those offsets need new values and a CRC copy is not enough. a patched `.ko` loads only on the one kernel build it was patched for.

the checked-in `module/qp_refresh120.c` is older than the shipped `.ko`: it defines no `dry_run`. rebuild from it and you lose that parameter — and the 120 module then has no way to inspect the driver without patching it.

## license

GPL-2.0. see [LICENSE](LICENSE).
