# Building the module

The custom-frequency module was built locally against the exact kernel build. The new build has not been loaded on a router.

- OpenWrt SDK 25.12.5, mediatek/filogic, GCC 14.3.0, musl, aarch64_cortex-a53.
- Kernel 6.12.94, kernel package `6.12.94~5a6c1f71be683ae9980b15d3ce73e24d-r1`.
- Vermagic: `6.12.94 SMP mod_unload aarch64`.
- Reference module SHA-256: `87b319aa86427a68f900e5b87683952cf51782c9a18215f25141d55f28b61a24`.
- Source SHA-256: `c03966a9b5b835f2c1eadef47c6eb58a0feedd591c74d5fbf2cc36503dd11029`.
- Header SHA-256: `553d1fbaa55b04d178b06b7acd49502e89847415bb6df5f87a7cee217635e20d`.
- Parameters: `run_test`, `target_mhz`, `hold_seconds`, `allow_unsafe`. Manual loading only; no modules_install.

## Build requirements

Use the exact prepared kernel build, including configuration, generated headers, Module.symvers and the matching cross-toolchain. Matching uname -r alone is insufficient. Do not bypass vermagic or modversions.

From the repository root on Linux/WSL:

```sh
sh source/build.sh "$PWD/source" "$PWD/build" "$OPENWRT_SDK"
```

OPENWRT_SDK must point to the exact SDK directory. The script accepts source, output and SDK directories. It builds in a temporary directory, checks vermagic and imported symbols against Module.symvers, and exports the module plus build metadata. It does not install or load anything.

Alternatively, from source/ with the corresponding build paths:

```sh
make -C "$KERNEL_BUILD" M="$PWD" ARCH=arm64 \
  CROSS_COMPILE="$OPENWRT_CROSS_PREFIX" modules
modinfo mt7981_oc_hold.ko
sha256sum mt7981_oc_hold.ko
```

Your binary checksum may differ. Update SHA in oc.sh to match your own module only after verifying the exact kernel compatibility. Do not remove the checksum or platform guards.

## Clock handling

Input range: 1301..2000 MHz in 1 MHz steps. Both the CLI and module require explicit risk acknowledgement above 1700. The upper bound is an input limit, not a safe CPU frequency specification.

For POSDIV=0, PCW is rounded to the nearest integer to MHz × 2^25 / 40. Stock 1300 uses its separate read-only branch and original POSDIV=1. The status fields effective_mhz and effective_hz are calculated from register values, not measured by an independent frequency counter.

ARMPLL uses 32 PCW bits and a POSDIV shift of 4 in [clk-mt7981-apmixed.c](https://raw.githubusercontent.com/torvalds/linux/master/drivers/clk/mediatek/clk-mt7981-apmixed.c). The default 7 integer bits and PLL calculation are in [clk-pll.c](https://raw.githubusercontent.com/torvalds/linux/master/drivers/clk/mediatek/clk-pll.c). PLL driver limits are not CPU overclocking safety guarantees.

MMIO writes are limited to BUS_PLL_DIVIDER (0x104007c0), ARMPLL_CON0 (0x1001e200) and ARMPLL_CON1 (0x1001e204). ACLKEN_DIV (0x10400640) is read-only. The transition uses stop_machine on CPU0: clear bit 9, program the PLL, then set bit 9 again. Delays use CNTVCT with a 13 MHz timer reference. This is an experimental procedure, not supported by the manufacturer.

Register checks, stock-state verification, 70/74 °C thresholds and return on unload are implemented in the module. At target_mhz=1300 it reads registers without programming the PLL. The timer and temperature guard depend on a functioning kernel and cannot recover a complete CPU freeze.

Source is GPL-2.0-only. Comments mentioning the panel describe the module's origins; there is no panel or VPN dependency.

Further reading: [External kernel modules](https://docs.kernel.org/kbuild/modules.html), [Tainted kernels](https://docs.kernel.org/admin-guide/tainted-kernels.html).
