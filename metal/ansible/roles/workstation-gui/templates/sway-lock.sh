#!/bin/bash

# Avoid delay with waybar hiding
killall -SIGUSR1 waybar
light-locker-command -l
sleep 2
killall -USR1 waybar
