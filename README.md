# battery-limit

KernelSU module: keeps the battery in the healthy **40–80%** range for 24/7 plugged-in use (phone-as-server setups).

> ⚠️ **仅适用于当前 LineageOS（Redmi Note 9 5G / MT6853 / 内核 4.14.336）**
> 其他系统（MIUI、其他 ROM、其他 MTK 设备）**未做测试**。`/proc/mtk_battery_cmd/`
> 这个控制接口不同厂商/不同内核可能不存在、路径不同、甚至 0/1 极性相反，
> 刷错会把「停充」变成「强制充电」。**换系统前先核对你内核的 en_power_path 极性。**

## How it works

MTK 平台在 `/proc/mtk_battery_cmd/en_power_path` 暴露充电通路开关：

| value | behavior |
|---|---|
| `1` | 充电通路开启 — 充电中（电流为负） |
| `0` | 仅放电通路 — 停止充电，电池带负载（电流为正） |

`service.sh`（经 KernelSU 模块系统以 root 运行）每 30 秒轮询电量：

- 电量 **≥ 80%** → `echo 0 > en_power_path`（停止充电）
- 电量 **≤ 60%** → `echo 1 > en_power_path`（恢复充电）

本机实测（Redmi Note 9 5G，MT6853，内核 4.14.336）：
- `en_power_path=0` → 电流 **+215 mA**（放电/电池供电）
- `en_power_path=1` → 电流 **-453 mA**（充电）

## 如何测试极性（适配你自己的设备）

`en_power_path` 的 0/1 含义**不是标准**，不同厂商/内核可能相反。改源码前先原地测，三分钟搞定：

**第 1 步：先确认电流符号约定**（正数=放电 还是 正数=充电）
```sh
# 拔掉充电线（此时一定是在放电），读电流：
adb shell "cat /sys/class/power_supply/battery/current_now"
# 记下这个符号：此刻是「放电」，它的符号就代表放电。
# 本机：拔线 = +570 mA → 正数 = 放电；负数 = 充电。（多数 MTK 如此，但不绝对）
```

**第 2 步：逐个读取 en_power_path 的两个值对应的电流方向**
```sh
# 插上充电线，分别写 0 和 1，看电流符号和大小变化：
adb shell "echo 0 > /proc/mtk_battery_cmd/en_power_path; sleep 6; cat /sys/class/power_supply/battery/current_now"
adb shell "echo 1 > /proc/mtk_battery_cmd/en_power_path; sleep 6; cat /sys/class/power_supply/battery/current_now"
```
对照第 1 步的符号约定，判断：
- 哪个值让电流为「放电方向」→ 那个值就是**停充**
- 哪个值让电流为「充电方向」→ 那个值就是**充电**

**第 3 步：按你测出的极性改 `service.sh`**（只有两行）：
```sh
# 电量 ≥ 80% 停充：echo <停充值> > $CMD
# 电量 ≤ 60% 充电：echo <充电值> > $CMD
```
例：本机测出 0=停充、1=充电，所以是 `echo 0`（≥80%）、`echo 1`（≤60%）。

> 注意：有些内核没有 `/proc/mtk_battery_cmd/`（路径可不同），
> 它可能藏在 `/sys/class/power_supply/battery/` 下的其它节点（如
> `input_suspend`、`charging_enabled`、`battery_charging_limit`），
> 原理一样：读电流方向来判断。

## Install

KernelSU 管理器 → 模块 → 从存储安装 → `battery-limit-v1.1.zip`。

手动：

```sh
adb push battery-limit-v1.1.zip /data/local/tmp/
adb shell "mkdir -p /data/adb/modules/battery_charge_limit"
adb shell "busybox unzip /data/local/tmp/battery-limit-v1.1.zip -d /data/adb/modules/battery_charge_limit"
adb shell "chmod 755 /data/adb/modules/battery_charge_limit/service.sh"
adb reboot
```

## Verify

```sh
adb shell "cat /proc/mtk_battery_cmd/en_power_path"      # 0=停充(放电) 1=充电
adb shell "cat /sys/class/power_supply/battery/capacity" # 会停在 60-80% 区间
adb shell "cat /sys/class/power_supply/battery/current_now" # 正=放电 负=充电
```

## 临时强制充满（出远门前）

```sh
adb shell "echo 1 > /proc/mtk_battery_cmd/en_power_path"
```

## License

GPL-3.0