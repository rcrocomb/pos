#!/bin/bash

governor=performance
if [ $# -eq 1 ]; then
	governor=$1
fi

echo "Chose governor as '$governor'"

# 'possible' is a range like '0-27'
# at least on our simple systems
max=$(cat /sys/devices/system/cpu/possible | cut -d"-" -f2)
echo "Found max core index (#cpus - 1) as ${max}"

for x in $(seq 0 ${max}); do
	cpufreq-set -c ${x} -g ${governor}
	if [ $? -ne 0 ]; then
		echo "Failed to set '$governor' governor on CPU $x"
	fi
done

cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
