set -l profile personal
if set -q AI_DEFAULT_PROFILE
    set profile "$AI_DEFAULT_PROFILE"
end
if set -q AI_PROFILE
    set profile "$AI_PROFILE"
end

if test -n "$profile"
    set -l root "$HOME/.local/share/ai/profiles/$profile"
    if set -q AI_PROFILES_DIR
        set root "$AI_PROFILES_DIR/$profile"
    end
    if test -f "$root/env.fish"
        source "$root/env.fish"
    end
end
