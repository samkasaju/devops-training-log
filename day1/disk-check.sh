#!/bin/bash

# Check that exactly two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path> <threshold>"
    exit 2
fi

PATH_TO_CHECK="$1"
THRESHOLD="$2"

# Check that the path exists
if [ ! -d "$PATH_TO_CHECK" ]; then
    echo "Error: Directory does not exist."
    exit 2
fi

# Check that threshold is a number between 1 and 100
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -lt 1 ] || [ "$THRESHOLD" -gt 100 ]; then
    echo "Error: Threshold must be an integer between 1 and 100."
    exit 2
fi

# Get disk usage percentage
USAGE=$(df -P "$PATH_TO_CHECK" | awk 'NR==2 {gsub("%","",$5); print $5}')

echo "Disk usage: ${USAGE}%"
echo "Threshold: ${THRESHOLD}%"

# Compare usage with threshold
if [ "$USAGE" -gt "$THRESHOLD" ]; then
    echo "WARNING: Disk usage is above threshold!"
    echo "Top 5 largest directories:"

    du -x --max-depth=1 "$PATH_TO_CHECK" 2>/dev/null | sort -nr | head -n 5

    exit 1
else
    echo "Disk usage is within threshold."
    exit 0
fi
