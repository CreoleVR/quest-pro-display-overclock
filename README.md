# Quest Pro Display Overclock

magisk module that unlocks 100, 110 and 120 hz on the meta quest pro (seacliff). the panel ships capped at 90 hz; this appends the higher rates so any openxr app can select them. 120 hz is the clean ceiling — ~186 hz is the hard math limit at the panel's fixed pixel clock.

nothing is written to any partition. the patch lives in kernel memory and is re-applied every boot, so disabling the module (or booting without it) returns the headset to stock 90 hz.

## requirements

- meta quest pro (seacliff)
- rooted with magisk
- the prebuilt `qp_refresh120.ko` targets the stock seacliff kernel; on any other kernel build it fails its own sanity checks and leaves you at 90 hz

## install

1. flash `qp_refresh120.zip` in the magisk app (build it with the command below, or grab it from releases)
2. reboot
3. select 120 hz in any openxr app

## uninstall

disable or remove the module in magisk and reboot. fully reverts to stock.

## how it works

the msm/sde dsi driver builds its drm mode list once, from `panel->dfps_caps.dfps_list[]` (one mode per refresh rate). the module appends 100/110/120 to that list, bumps `max_refresh_rate` and `num_display_modes`, and nulls `display->modes` so the connector rebuilds the list on the next probe. the target symbol (`dsi_display_get_active_displays`) is kaslr'd, so its address is resolved from `/proc/kallsyms` at boot and passed in as module params. before writing anything the module validates the struct layout (dfps type, list length, min/max rates, mode multiplier) and aborts untouched if any field is implausible — this is what keeps it safe on an unexpected kernel.

two boot stages:

- **post-fs-data.sh** — resolves the symbol, loads the module, reprobes the connector, waits for the 120 mode to appear in drm.
- **service.sh** — after boot it opens the runtime rate list (`debug.oculus.allRefreshRates=1`) and bounces **only** the two display composers so they re-enumerate the new modes. it deliberately never touches zygote or the sensor/tracking/passthrough services: tearing those down races the syncboss mcu re-download and can wedge tracking. it also gates on the sensor hub being quiet before acting. head tracking and passthrough are preserved.

## build from source

point the module at a prepared seacliff kernel tree and build out-of-tree:

```
make -C <kernel_out> M=$PWD/module modules
cp module/qp_refresh120.ko magisk/
```

## package the flashable zip

```
cd magisk
zip -X -r -9 ../qp_refresh120.zip module.prop post-fs-data.sh service.sh qp_refresh120.ko META-INF
```

## license

GPL-2.0. see [LICENSE](LICENSE).
