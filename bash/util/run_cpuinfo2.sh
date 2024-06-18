#!/bin/bash

# Has the advantage of printing the core index next to the frequency data,
# which is nice when they have variable limits, as w/ some Intel CPUs, e.g.
# the 14900KF.  However, it does run cpufreq-info AND bc once per core,
# whereas the "stupid" version has a single 'cat' and 'grep'.

max=$(cat /sys/devices/system/cpu/online | cut -d"-" -f2)

while true; do
	echo $(date)
	for x in $(seq 0 ${max}); do
		printf "%2d MHz -> " $x
		f=$(cpufreq-info -c ${x} -f)
		f=$(bc -l <<< ${f}/1000)
		printf "%7.3f\n" ${f}
	done
	sleep 5
done

