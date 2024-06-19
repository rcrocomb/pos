#!/bin/bash

filename=$1

ffprobe -print_format json -show_frames "${filename}" 2>/dev/null | jq -c '.frames[]|select(.key_frame == 1 and .media_type == "video")|{pkt_pts,pkt_pts_time,pkt_dts,pkt_dts_time}'
