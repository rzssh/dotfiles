function rec
    function _notify -a msg
        notify-send -e -t 1500 -a "Screen Recording" "$msg"
    end

    set -l no_audio false
    set -l recorder_args
    for arg in $argv
        if contains -- "$arg" -na --no-audio
            set no_audio true
        else
            set -a recorder_args "$arg"
        end
    end

    set rand_hex (printf '%08x' (random 0 2147483647))
    set output_file "$HOME/Documents/recordings/output-$rand_hex.mp4"

    mkdir -p (dirname $output_file)

    echo "Recording with wf-recorder..."

    set -l audio_args
    if not $no_audio
        set sink (wpctl inspect @DEFAULT_AUDIO_SINK@ | string match --regex --groups-only 'node\.name = "([^"]+)"')
        set audio_source "$sink.monitor"

        if test -n "$audio_source"
            echo "Capturing audio from: $audio_source"
            set audio_args --audio="$audio_source"
        else
            echo "No audio source found, recording video only"
        end
    end

    wf-recorder $audio_args --codec=libx264 --codec-param="preset=medium" --codec-param="crf=28" -f $output_file $recorder_args

    echo "Recording saved to: $output_file"

    echo -n $output_file | wl-copy
    echo "Path copied to clipboard"

    _notify "Saved and copied: "(basename "$output_file")
end
