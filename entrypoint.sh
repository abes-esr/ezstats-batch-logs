#!/bin/sh
echo "Starting container Ezstats Batch Logs..."
crond -f -l 8 -d 8 -L /dev/stdout
