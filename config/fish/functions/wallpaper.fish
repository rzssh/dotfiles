function wallpaper --description "Manage wallpapers via DMS"
    set -l dir "$HOME/wallpapers"
    set -l live "$dir/.live"

    function _notify -a msg
        notify-send -e -t 1500 -a Wallpaper "$msg"
    end

    function _wp_get
        dms ipc call wallpaper get 2>/dev/null | string trim
    end

    function _wp_set -a img
        dms ipc call wallpaper set "$img" >/dev/null 2>&1
    end

    function _wp_black
        set -l b "$HOME/.cache/wallpaper-black.png"
        test -f "$b"; or magick -size 1920x1080 xc:black "$b" 2>/dev/null
        echo "$b"
    end

    function _wp_clear
        dms ipc call wallpaper clear >/dev/null 2>&1
    end

    function _wp_current
        set -l p (_wp_get)
        test "$p" = "$HOME/.cache/wallpaper-black.png"; and return
        test -n "$p" -a -f "$p"; and echo "$p"
    end

    function _wp_find
        command find -L $argv -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.bmp' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.jxl' -o -iname '*.avif' -o -iname '*.heif' -o -iname '*.exr' \) 2>/dev/null
    end

    function _link_area -a area
        set -l dir "$HOME/wallpapers"
        set -l live "$dir/.live"
        command mkdir -p "$live"
        set -l src "$dir"
        test "$area" = root; or set src "$dir/.$area"
        test -d "$src" -a -r "$src"; or return
        for f in (_wp_find "$src")
            command ln -sf "$f" "$live/$area"__(string replace -r '.*/' '' "$f")
        end
    end

    function _unlink_area -a area
        set -l live "$HOME/wallpapers/.live"
        command find "$live" -maxdepth 1 -type l -name "$area"'__*' -delete 2>/dev/null
    end

    function _rebuild_live
        set -l live "$HOME/wallpapers/.live"
        command mkdir -p "$live"
        command find "$live" -maxdepth 1 -type l -delete 2>/dev/null
        test (wallpaper-state get exclude_default) != true; and _link_area root
        for cat in (wallpaper-state restricted-folders | string split " ")
            test (wallpaper-state get allow_$cat) = true; and _link_area $cat
        end
    end

    function _ensure_live
        set -l live "$HOME/wallpapers/.live"
        set -l n (command ls -A "$live" 2>/dev/null | count)
        if not test -d "$live"; or test "$n" -eq 0
            _rebuild_live
        end
    end

    function _live_images
        _wp_find "$HOME/wallpapers/.live"
    end

    function _set_random
        set -l imgs (_live_images)
        test (count $imgs) -eq 0; and _notify "No images"; and return 1
        set -l img $imgs[(random 1 (count $imgs))]
        set -l cur (_wp_current)
        test -n "$cur"; and wallpaper-state set previous_image "$cur"
        _wp_set "$img"
        _notify (string replace -r '.*/' '' (command realpath "$img"))
    end

    function _step_seq -a delta -a arrow
        _ensure_live
        set -l imgs (_live_images | sort)
        set -l n (count $imgs)
        test $n -eq 0; and _notify "No images"; and return 1
        set -l cur (_wp_current)
        set -l idx 1
        if test -n "$cur"
            set -l f (contains -i -- "$cur" $imgs)
            test -n "$f"; and set idx $f
        end
        set -l z (math "$idx - 1 + $delta")
        set -l target (math "($z % $n + $n) % $n + 1")
        set -l img $imgs[$target]
        test -n "$cur"; and wallpaper-state set previous_image "$cur"
        _wp_set "$img"
        _notify "$arrow"(string replace -r '.*/' '' (command realpath "$img"))
    end

    switch $argv[1]
        case random
            _ensure_live
            _set_random

        case next
            _step_seq 1 "→ "

        case prev previous
            _step_seq -1 "← "

        case undo
            set -l img (wallpaper-state get previous_image)
            test -z "$img" -o ! -f "$img"; and _notify "No previous"; and return 1
            set -l cur (_wp_current)
            test -n "$cur"; and wallpaper-state set previous_image "$cur"
            _wp_set "$img"
            _notify "↺ "(string replace -r '.*/' '' (command realpath "$img"))

        case toggle
            set -l cur (_wp_current)
            if test -n "$cur"
                wallpaper-state set saved_image "$cur"
                _wp_clear
                _notify OFF
            else
                _ensure_live
                set -l img (wallpaper-state get saved_image)
                if test -z "$img" -o ! -f "$img"
                    set -l imgs (_live_images)
                    test (count $imgs) -gt 0; and set img $imgs[(random 1 (count $imgs))]
                end
                if test -n "$img" -a -f "$img"
                    _wp_set "$img"
                    _notify ON
                end
            end

        case toggle-nsfw toggle-restricted toggle-explicit toggle-default
            _ensure_live
            set -l name (string replace "toggle-" "" $argv[1])
            if test "$name" = default
                if test (wallpaper-state get exclude_default) = true
                    wallpaper-state set exclude_default false
                    _link_area root
                    _notify "default: ON"
                else
                    wallpaper-state set exclude_default true
                    _unlink_area root
                    test -z (_wp_current); and _set_random
                    _notify "default: OFF"
                end
            else
                if test (wallpaper-state get allow_$name) = true
                    wallpaper-state set allow_$name false
                    _unlink_area $name
                    test -z (_wp_current); and _set_random
                    _notify "$name: OFF"
                else
                    wallpaper-state set allow_$name true
                    _link_area $name
                    _notify "$name: ON"
                end
            end

        case show
            set -l img (_wp_current)
            test -z "$img"; and return
            set -l real (command realpath "$img")
            echo "$real" | wl-copy; and _notify Copied; and echo "$real"

        case refresh rebuild
            _rebuild_live
            _notify "Rebuilt "(count (_live_images))" wallpapers"

        case reload reapply
            set -l cur (_wp_get)
            test -z "$cur"; and _notify "No wallpaper"; and return 1
            set -l real (command realpath "$cur" 2>/dev/null)
            test -z "$real" -o ! -f "$real"; and _notify "Missing file"; and return 1
            if test "$cur" != "$real"
                _wp_set "$real"
            else
                set -l parent (basename (dirname "$real"))
                set -l livename (basename "$real")
                test "$parent" != wallpapers; and set livename "$parent"__"$livename"
                set -l livepath "$HOME/wallpapers/.live/$livename"
                if test -L "$livepath"
                    _wp_set "$livepath"
                else
                    _wp_set "$real"
                end
            end
            _notify "⟳ reloaded"

        case status
            set -l cur (_wp_current)
            test -n "$cur"; and echo "enabled: true"; or echo "enabled: false"
            test -n "$cur"; and echo "image: "(command realpath "$cur"); or echo "image:"
            echo "nsfw: "(wallpaper-state get allow_nsfw)"  restricted: "(wallpaper-state get allow_restricted)"  explicit: "(wallpaper-state get allow_explicit)"  exclude_default: "(wallpaper-state get exclude_default)
            echo "available: "(count (_live_images))

        case '*'
            echo "Usage: wallpaper {random|next|prev|undo|toggle|reload|toggle-nsfw|toggle-restricted|toggle-explicit|toggle-default|show|refresh|status}"
    end
end
