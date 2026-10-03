# battery-limit

KernelSU module: keeps the battery in the healthy **40–80%** range for 24/7 plugged-in use (phone-as-server setups).

## How it works

MTK platforms expose the charging path switch at
`/proc/mtk_battery_cmd/en_power_path`:

| value | behavior |
|---|---|
| `0` | charging path enabled — battery charges |
| `1` | discharge path only — charging stops, battery holds the load |

`service.sh` (runs as root via the KernelSU module system) polls the
capacity every 30 s:

- capacity **≥ 80%** → `echo 1 > en_power_path` (stop charging)
- capacity **≤ 60%** → `echo 0 > en_power_path` (resume charging)

Verified on Redmi Note 9 5G (MT6853, kernel 4.14.336): charging +396 mA
with `0`, discharging -280 mA with `1`.

## Install

KernelSU manager → Modules → Install from storage → `battery-limit-v1.0.zip`.

Manual:

```sh
adb push battery-limit-v1.0.zip /data/local/tmp/
adb shell "mkdir -p /data/adb/modules/battery_charge_limit"
adb shell "busybox unzip /data/local/tmp/battery-limit-v1.0.zip -d /data/adb/modules/battery_charge_limit"
adb shell "chmod 755 /data/adb/modules/battery_charge_limit/service.sh"
adb reboot
```

## Verify

```sh
adb shell "cat /proc/mtk_battery_cmd/en_power_path"      # 0=charging 1=stopped
adb shell "cat /sys/class/power_supply/battery/capacity" # parks near 80% (on purpose)
```

## Force full charge temporarily

```sh
adb shell "echo 0 > /proc/mtk_battery_cmd/en_power_path"
```

## License

GPL-3.0
