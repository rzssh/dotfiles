#!/usr/bin/env bash

set -u

state_dir="${XDG_RUNTIME_DIR:-/tmp}/dms-screenshot"
mkdir -p "$state_dir"

case "${1:-}" in
    toggle-silent)
        if [[ -e "$state_dir/silent" ]]; then
            rm "$state_dir/silent"
            value=on
        else
            touch "$state_dir/silent"
            value=off
        fi
        notify-send -e -t 1500 -a Screenshot "Screenshot notifications: $value"
        ;;
    toggle-send)
        if [[ -e "$state_dir/send" ]]; then
            rm "$state_dir/send"
            value=off
        else
            touch "$state_dir/send"
            value=on
        fi
        notify-send -e -t 1500 -a Screenshot "Phone auto-send: $value"
        ;;
    region|full)
        flags=()
        [[ -e "$state_dir/silent" ]] && flags+=(--no-notify)
        path="$(dms screenshot "$1" "${flags[@]}")" || exit
        [[ -e "$state_dir/send" ]] || exit 0
        device="$(kdeconnect-cli --list-available --id-only 2>/dev/null | head -n 1)"
        [[ -n "$device" ]] || exit 0
        kdeconnect-cli --device "$device" --share "$path" >/dev/null 2>&1 &
        ;;
    *)
        exit 2
        ;;
esac
