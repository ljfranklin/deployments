#!/bin/bash

rofi -show ssh -no-parse-known-hosts -font 'hack 12' -theme solarized_alternate -terminal alacritty \
  -ssh-command '{terminal} -e bash -i -c "{ssh-client} {host}"'
