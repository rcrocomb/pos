#!/bin/bash

echo "Getting CPU limits and setting new values"
echo "--------------------------------------------------------------------------------"

max=$(cat /sys/devices/system/cpu/online | cut -d"-" -f2)
echo "Found max core index (#cpus - 1) as ${max}"

for x in $(seq 0 ${max}); do
	current=$(cpufreq-info -c ${x} -p| cut -d' ' -f 2)
	# Value in MHz
	limit=$(cpufreq-info -c ${x} -l | cut -d' ' -f 2)
	printf "%2d --> from ${current} --> limit ${limit}\n" ${x}
	# No space between value and unit
	cpufreq-set -c ${x} -u "${limit}MHz"
done
