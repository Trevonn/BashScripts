#!/bin/bash

tscCheck() {
    # Check the value of the variable. Print a message to journalctl depending on the result
    if [[ $(cat /sys/devices/system/clocksource/clocksource0/current_clocksource) == "tsc" ]] then
        echo "TSC is active"
    else
        echo "TSC is not active" | systemd-cat -p emerg
        echo "TSC is not active"
    fi
}
