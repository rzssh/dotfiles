# Desktop notification when a long command finishes while the terminal is unfocused.
# Reproduces the ghostty/tmux "command done" notif that herdr swallows (it eats OSC 9/777).
# Tune the threshold (ms):
set -q notify_done_threshold; or set -g notify_done_threshold 15000

function __notify_done --on-event fish_postexec
    set -l last_status $status
    test "$CMD_DURATION" -lt "$notify_done_threshold"; and return

    # skip if you're looking at the terminal (ghostty focused)
    test "$(hyprctl activewindow -j 2>/dev/null | jq -r '.class' 2>/dev/null)" = com.mitchellh.ghostty
    and return

    set -l cmd (string sub -l 70 -- $argv[1])
    set -l secs (math -s1 $CMD_DURATION / 1000)
    if test $last_status -eq 0
        notify-send -e -a fish -t 6000 "✓ done  ("$secs"s)" "$cmd"
    else
        notify-send -e -a fish -u critical -t 8000 "✗ failed  (exit "$last_status", "$secs"s)" "$cmd"
    end
end
