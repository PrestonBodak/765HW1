#!/bin/bash

if [[ "$1" == "course-marker" ]]; then
	echo "This is a marker file!" > ../markers/marker.txt
	exit 0
fi
