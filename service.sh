#!/system/bin/sh
# Battery Charge Limit: keep the battery in the 40-80% healthy range.
# MTK: /proc/mtk_battery_cmd/en_power_path (0 = charge, 1 = stop/discharge).
# Runs as root via the KernelSU module system.

CMD=/proc/mtk_battery_cmd/en_power_path
BAT=/sys/class/power_supply/battery/capacity
HI=80
LO=60

[ -e "$CMD" ] || exit 0
[ -e "$BAT" ] || exit 0

# hold the chosen state so the script always starts in a known mode
echo 0 > "$CMD"

(
	while true; do
		cap=$(cat "$BAT" 2>/dev/null)
		case "$cap" in
			''|*[!0-9]*) sleep 30; continue ;;
		esac
		if [ "$cap" -ge "$HI" ]; then
			echo 1 > "$CMD"          # stop charging (battery holds the load)
		elif [ "$cap" -le "$LO" ]; then
			echo 0 > "$CMD"          # resume charging
		fi
		sleep 30
	done
) &
