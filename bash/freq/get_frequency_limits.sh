max=$(cat /sys/devices/system/cpu/possible | cut -d"-" -f2)
echo "Found max core index (#cpus - 1) as ${max}"

for x in $(seq 0 ${max}); do
	printf "%2d --> " ${x}
	cpufreq-info -c ${x} -l
done
