#!/bin/bash

# Store the current clocksource in a variable
local tscCheck=$(cat /sys/devices/system/clocksource/clocksource*/current_clocksource)

# Check the value of the variable. Print a message to journalctl depending on the result
if [ $tscCheck == "tsc" ] 
then
    echo 'TSC active' | systemd-cat -p info
else
    echo 'TSC not active' | systemd-cat -p emerg
fi
