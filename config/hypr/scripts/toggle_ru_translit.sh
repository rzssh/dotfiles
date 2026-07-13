#!/usr/bin/env bash
current=$(ibus engine)
if [ "$current" = "m17n:ru:translit" ]; then
    ibus engine xkb:us::eng
    notify-send -t 1000 "EN"
else
    ibus engine m17n:ru:translit
    notify-send -t 1000 "RU translit"
fi
