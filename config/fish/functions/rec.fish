function rec --description "Toggle screen recording"
    function _notify -a msg
        notify-send -e -t 1500 -a "Screen Recording" "$msg"
    end

    set -l no_audio false
    set -l stop_only false
    set -l recorder_args
    for arg in $argv
        if contains -- "$arg" -na --no-audio
            set no_audio true
        else if test "$arg" = --stop
            set stop_only true
        else
            set -a recorder_args "$arg"
        end
    end

    set -l runtime_dir "$XDG_RUNTIME_DIR"
    test -n "$runtime_dir"; or set runtime_dir /tmp
    set -l pid_file "$runtime_dir/razen-wf-recorder.pid"
    if test -f "$pid_file"
        set -l owner_pid (string trim < "$pid_file")
        if string match -qr '^[0-9]+$' -- "$owner_pid"; and test -r "/proc/$owner_pid/task/$owner_pid/children"
            for recorder_pid in (string split ' ' -- (string trim < "/proc/$owner_pid/task/$owner_pid/children"))
                if test -r "/proc/$recorder_pid/comm"; and string match -q wf-recorder (string trim < "/proc/$recorder_pid/comm")
                    kill -INT "$recorder_pid"
                    _notify "Stopping recording"
                    return
                end
            end
        else
            rm -f "$pid_file"
        end
    end
    $stop_only; and return 1

    set rand_hex (printf '%08x' (random 0 2147483647))
    set output_file "$HOME/Documents/recordings/output-$rand_hex.mp4"

    mkdir -p (dirname $output_file)

    set -l audio_args
    if not $no_audio
        set sink (wpctl inspect @DEFAULT_AUDIO_SINK@ | string match --regex --groups-only 'node\.name = "([^"]+)"')
        set audio_source "$sink.monitor"

        if test -n "$audio_source"
            set audio_args --audio="$audio_source"
        end
    end

    printf '%s\n' "$fish_pid" > "$pid_file"
    _notify "Recording started"
    wf-recorder $audio_args --codec=libx264 --codec-param="preset=medium" --codec-param="crf=28" -f $output_file $recorder_args
    set -l recorder_status $status
    if test (string trim < "$pid_file") = "$fish_pid"
        rm -f "$pid_file"
    end

    if test $recorder_status -ne 0
        _notify "Recording failed"
        return $recorder_status
    end

    printf '%s' "$output_file" | wl-copy
    _notify "Saved and copied: "(basename "$output_file")
end
