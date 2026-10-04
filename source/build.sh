#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
# Local Linux/WSL build only. Never installs/loads a module on a router.
set -eu
source_dir=${1:?source directory}
output_dir=${2:?new output directory}
sdk=${3:?exact OpenWrt SDK directory}
kernel=$sdk/build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/linux-6.12.94
cross=$sdk/staging_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/bin/aarch64-openwrt-linux-musl-
test -r "$kernel/Module.symvers"
test -r "$kernel/.config"
test -x "${cross}gcc"
test ! -e "$output_dir/mt7981_oc_hold.ko"
work=$(mktemp -d /tmp/mt7981-custom-oc-build.XXXXXXXX)
echo "BUILD_WORKDIR=$work"
export STAGING_DIR="$sdk/staging_dir/target-aarch64_cortex-a53_musl"
cp "$source_dir/mt7981_oc_hold.c" "$source_dir/mt7981_oc_freq.h" "$source_dir/Makefile" "$work/"
make -C "$kernel" M="$work" ARCH=arm64 CROSS_COMPILE="$cross" HOSTCC=/usr/bin/gcc V=1 modules
ko=$work/mt7981_oc_hold.ko
test "$(modinfo -F vermagic "$ko" | sed 's/[[:space:]]*$//')" = '6.12.94 SMP mod_unload aarch64'
"${cross}nm" -u "$ko" | while read -r _type name; do
 case "$name" in
 _printk|__stack_chk_fail|arm64_use_ng_mappings|of_machine_compatible_match|__ioremap_prot|iounmap|stop_machine|param_ops_bool|param_ops_uint|__init_work|queue_delayed_work_on|system_wq|cancel_delayed_work_sync|mutex_lock|mutex_unlock|__msecs_to_jiffies|delayed_work_timer_fn|init_timer_key|thermal_zone_get_temp|thermal_zone_get_zone_by_name|emergency_restart|scnprintf|__cpu_online_mask|__num_online_cpus|cpu_bit_bitmap|jiffies) ;;
 *) echo "UNEXPECTED_IMPORT=$name"; exit 1;;
 esac
 awk -v name="$name" '$2==name {found=1;print} END {if(!found)exit 1}' "$kernel/Module.symvers"
done
mkdir -p "$output_dir"
"${cross}objdump" -dr "$ko" > "$work/disassembly.txt"
modinfo "$ko" | sed 's|^filename:.*|filename:       mt7981_oc_hold.ko|' > "$work/modinfo.txt"
cp -n "$ko" "$work/disassembly.txt" "$work/modinfo.txt" "$output_dir/"
sha256sum "$ko" "$work/mt7981_oc_hold.c" "$work/mt7981_oc_freq.h"
echo 'BUILD_OK_NOT_LOADED'
