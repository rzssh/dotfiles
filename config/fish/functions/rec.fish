function rec --description "Toggle screen recording"
    function _notify -a msg
        notify-send -e -t 1500 -a "Screen Recording" "$msg"
    end

    set -l no_audio false
    set -l with_mic false
    set -l stop_only false
    set -l recorder_args
    for arg in $argv
        if contains -- "$arg" -na --no-audio
            set no_audio true
        else if test "$arg" = --mic
            set with_mic true
        else if test "$arg" = --stop
            set stop_only true
        else
            set -a recorder_args "$arg"
        end
    end

    if pkill -INT -x wf-recorder
        _notify "Stopping recording"
        return
    end
    $stop_only; and return 1

    set rand_hex (printf '%08x' (random 0 2147483647))
    set output_file "$HOME/Documents/recordings/output-$rand_hex.mp4"

    mkdir -p (dirname $output_file)

    set -l audio_args
    set -l audio_modules
    if not $no_audio
        set sink (wpctl inspect @DEFAULT_AUDIO_SINK@ | string match --regex --groups-only 'node\.name = "([^"]+)"')
        set audio_source "$sink.monitor"

        if $with_mic
            set source (wpctl inspect @DEFAULT_AUDIO_SOURCE@ | string match --regex --groups-only 'node\.name = "([^"]+)"')
            set mix_sink "wf_recorder_mix_$rand_hex"

            if test -z "$sink" -o -z "$source"
                _notify "Audio device not found"
                return 1
            end

            for module_args in "module-null-sink sink_name=$mix_sink rate=48000 channels=2" "module-loopback source=$sink.monitor sink=$mix_sink latency_msec=1" "module-loopback source=$source sink=$mix_sink latency_msec=1"
                set module (pactl load-module (string split ' ' $module_args))
                if test $status -ne 0
                    for loaded_module in $audio_modules
                        pactl unload-module $loaded_module
                    end
                    _notify "Audio mix failed"
                    return 1
                end
                set -a audio_modules $module
            end

            set audio_source "$mix_sink.monitor"
        end

        if test -n "$audio_source"
            set audio_args --audio="$audio_source"
        end
    end

    _notify "Recording started"
    wf-recorder $audio_args --codec=libx264 --codec-param="preset=medium" --codec-param="crf=28" -f $output_file $recorder_args
    set -l recorder_status $status

    for module in $audio_modules
        pactl unload-module $module
    end

    if test $recorder_status -ne 0
        _notify "Recording failed"
        return $recorder_status
    end

    printf '%s' "$output_file" | wl-copy
    _notify "Saved and copied: "(basename "$output_file")
end
