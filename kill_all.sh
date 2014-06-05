#!/bin/sh
echo "closing all applications which contain " $1
ps aux | grep -e $1 | grep -v grep | awk '{print $2}' | xargs -i kill {}
