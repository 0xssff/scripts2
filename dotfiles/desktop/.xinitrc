#!/bin/sh
touch "$HOME/.xinitrc_log" && chmod 600 "$HOME/.xinitrc_log" && "$HOME/bin/startdwm" > "$HOME/.xinitrc_log" 2>&1