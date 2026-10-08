# WR3000P: runtime CPU overclocking without flashing BL2

Source code for an experimental MT7981 overclocking script and kernel module. Changes the CPU clock at runtime, without modifying BL2, flash partitions, Device Tree, voltage or VPN settings. No autostart.

Only WR3000S v1 ubootmod with OpenWrt 25.12.5 r33051-f5dae5ece4, kernel 6.12.94 and ABI 5a6c1f71be683ae9980b15d3ce73e24d is supported. The script refuses other builds.

## Commands

After building, place oc.sh and the matching mt7981_oc_hold.ko together in /tmp/wr3000s-oc. Run over SSH as root:

```sh
cd /tmp/wr3000s-oc
sh ./oc.sh check       # compatibility and module checksum
sh ./oc.sh 1400        # request 1400 MHz
sh ./oc.sh 1500        # custom frequency example
sh ./oc.sh status      # state, temperature and available memory
sh ./oc.sh 1300        # return to stock and verify registers
```

Accepts integer frequencies from 1301 to 2000 MHz. Above 1700 MHz is not recommended and requires --risk. The optional second argument sets a return timer, for example sh ./oc.sh 1640 120. Without it, the timer is disabled.

With a stock BL2, reboot restores 1300 MHz and clears /tmp. This package does not undo an overclock previously written into BL2.

Entry requires a temperature below 70 °C. The module returns to stock at 74 °C, on sensor/register errors, timer expiry or normal unload. The script refuses to replace another tool's loaded module.

## Use at your own risk

The custom-frequency build has not been tested on hardware. A complete CPU freeze can prevent rollback and require a power cycle. Hardware damage and data loss are possible. Do not run during firmware flashing or updates.

This repository contains source only, without prebuilt .ko files or archives. [Building](source/BUILD.md) requires the exact kernel build. Update the module SHA in oc.sh after your own build, without bypassing compatibility checks. License: [GPL-2.0-only](LICENSE).
