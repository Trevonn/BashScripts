#!/bin/bash

# This function checks the processor's current clocksource
# If that clocksource is TSC it prints yes. If not it prints no

function arewetsc() {
    tsc=$(cat /sys/devices/system/clocksource/clocksource*/current_clocksource)
    if [ $tsc == "tsc" ] 
    then
        echo "Yes"
    else
        echo "No"
    fi
}

# Store the result of arewetsc in a variable
tscCheck=$(arewetsc)

# Check the value of the variable. Print a message to journalctl depending on the result
if [ $tscCheck == "Yes" ] 
then
    echo 'TSC active' | systemd-cat -p info
else
    echo 'TSC not active' | systemd-cat -p emerg
fi
