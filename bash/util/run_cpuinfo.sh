#!/bin/bash

while true; do
	echo $(date)
	cat /proc/cpuinfo | egrep MHz
	sleep 5
done
