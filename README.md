# ФОРК НА РАБОТУ ДРУГОГО АВТОРА, СПЕЦИАЛЬНО ДЛЯ РОУТЕРОВ CUDY WR3000P.
Содержание скрипта оставил неизменным, как и основные команды. Изменил лишь строки отвечающие за совместимость с WR3000P.
Беспокоиться о проблемах из за с принудительной совместимостью не стоит, так как у WR3000s и WR3000p совершенно одинаковые процессоры.

# WR3000P: runtime CPU overclocking without flashing BL2

Source code for an experimental MT7981 overclocking script and kernel module. Changes the CPU clock at runtime, without modifying BL2, flash partitions, Device Tree, voltage or VPN settings. No autostart.

Only WR3000P v1 ubootmod with OpenWrt 25.12.5 r33051-f5dae5ece4, kernel 6.12.94 and ABI 5a6c1f71be683ae9980b15d3ce73e24d is supported. The script refuses other builds.

## Commands

After building, place oc.sh and the matching mt7981_oc_hold.ko together in /tmp/wr3000p-oc. Run over SSH as root:

```sh
cd /tmp/wr3000p-oc
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


## ДЛЯ ПОСТОЯННОГО РАЗГОНА:

Проверьте способом описанным выше стабильные частоты для вашего роутера. 
После чего, можете осуществить постоянный разгон путем перемещения файлов mt7981_oc_hold.ko и oc.sh в любую папку в постоянной памяти роутера. Например, можете создать папку OC в папке etc (/etc/OC) и закинуть в нее вышеуказанные файлы. Далее, чтобы разгон применялся автоматически, при каждом старте роутера - откройте консоль и бахните туда следующую команду: sed -i '/exit 0/i \(sleep 60 && cd /etc/OC && sh ./oc.sh 1640) &' /etc/rc.local
По итогу, разгон будет стартовать по истечению одной минуты, после запуска роутера. Минута перед запуском включена намеренно для того, чтобы обезопасить пользователя от ошибки или нестабильности при разгоне. Тоесть, если частота окажется запредельной для вашего кремния, то у вас будет минута, чтобы выдернуть команду из автозагрузки. 
При возникновении проблем, в течении 60 секунд просто введите команду sed -i '/oc.sh/d' /etc/rc.local в консоль и разгон успешно дропнется из автозапуска. 
