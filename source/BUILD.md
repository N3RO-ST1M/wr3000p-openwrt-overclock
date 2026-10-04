# Сборка модуля

Кастомный `.ko` пересобран локально под точный kernel build. На роутере новая сборка не загружалась.

- OpenWrt SDK 25.12.5, mediatek/filogic, GCC 14.3.0, musl, aarch64_cortex-a53.
- Kernel 6.12.94, kernel-package `6.12.94~5a6c1f71be683ae9980b15d3ce73e24d-r1`.
- Vermagic: `6.12.94 SMP mod_unload aarch64`.
- SHA256: `87b319aa86427a68f900e5b87683952cf51782c9a18215f25141d55f28b61a24`.
- SHA256 исходника: `c03966a9b5b835f2c1eadef47c6eb58a0feedd591c74d5fbf2cc36503dd11029`.
- SHA256 заголовка: `553d1fbaa55b04d178b06b7acd49502e89847415bb6df5f87a7cee217635e20d`.
- Параметры: `run_test`, `target_mhz`, `hold_seconds`, `allow_unsafe`. Загрузка только вручную. Команда modules_install не используется.

Сборка в Linux требует точного kernel build: конфигурации, generated headers, Module.symvers и соответствующего cross-toolchain. Одного совпадения `uname -r` недостаточно. Если SDK не содержит необходимых артефактов, нужен kernel build с совпадающей конфигурацией. Обходить vermagic или modversions нельзя.

```sh
make -C "$KERNEL_BUILD" M="$PWD" ARCH=arm64 \
  CROSS_COMPILE="$OPENWRT_CROSS_PREFIX" modules
modinfo mt7981_oc_hold.ko
sha256sum mt7981_oc_hold.ko
```

Сборка через source/build.sh принимает каталог source, новый каталог результата и каталог точного SDK. Проверяет vermagic и импорты по Module.symvers. Никаких flash/MTD/DT/voltage/clk_set_rate API.

Диапазон ввода: 1301..2000 МГц, шаг 1. В модуле и CLI выше 1700 требуется отдельное согласие на риск. 2000 является ограничением ввода, не пределом безопасной частоты CPU. PCW рассчитывается при POSDIV=0 как ближайшее целое к MHz × 2^25 / 40. Для штатных 1300 сохраняется отдельная read-only ветка и штатный POSDIV=1. В status частота округлена до целых МГц; effective_hz сохраняет расчёт с точностью до Гц. Это расчёт по регистрам, не аппаратное измерение.

Формат ARMPLL: 32 PCW bits, сдвиг POSDIV 4 в [clk-mt7981-apmixed.c](https://raw.githubusercontent.com/torvalds/linux/master/drivers/clk/mediatek/clk-mt7981-apmixed.c); 7 integer bits по умолчанию и расчёт частоты в [clk-pll.c](https://raw.githubusercontent.com/torvalds/linux/master/drivers/clk/mediatek/clk-pll.c). Диапазон PLL в драйвере не является спецификацией безопасной частоты CPU.

MMIO-записи выполняются только в BUS_PLL_DIVIDER (0x104007c0), ARMPLL_CON0 (0x1001e200) и ARMPLL_CON1 (0x1001e204). ACLKEN_DIV (0x10400640) только читается. Переход выполняется через stop_machine на CPU0: bit 9 временно сбрасывается, PLL программируется, затем bit 9 устанавливается обратно. Задержки используют CNTVCT с опорной частотой таймера 13 МГц. Это экспериментальная процедура, не поддержанная производителем.

Проверки регистров, штатного состояния, температурные пороги 70/74 °C и возврат при выгрузке реализованы в модуле. При target_mhz=1300 выполняется только чтение регистров, PLL не программируется. Таймер и температурная защита зависят от работающего ядра и не защищают от полного зависания CPU.

Исходник включён под GPL-2.0-only. Комментарии с упоминанием панели описывают происхождение модуля. Зависимости от панели или VPN в нём нет.

Ссылки: https://docs.kernel.org/kbuild/modules.html и https://docs.kernel.org/admin-guide/tainted-kernels.html
