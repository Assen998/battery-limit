#!/system/bin/sh
# Battery Charge Limit: keep the battery in the 40-80% healthy range.
# MTK: /proc/mtk_battery_cmd/en_power_path
#   en_power_path=0 -> STOP charging (battery holds the load, current +ve)
#   en_power_path=1 -> charge (current -ve)
# Runs as root via the KernelSU module system.

CMD=/proc/mtk_battery_cmd/en_power_path
BAT=/sys/class/power_supply/battery/capacity
HI=80
LO=60

[ -e "$CMD" ] || exit 0
[ -e "$BAT" ] || exit 0

(
	while true; do
		cap=$(cat "$BAT" 2>/dev/null)
		case "$cap" in
			''|*[!0-9]*) sleep 30; continue ;;
		esac
		if [ "$cap" -ge "$HI" ]; then
			echo 0 > "$CMD"          # stop charging (>=80%)
		elif [ "$cap" -le "$LO" ]; then
			echo 1 > "$CMD"          # resume charging (<=60%)
		fi
		sleep 30
	done
) &