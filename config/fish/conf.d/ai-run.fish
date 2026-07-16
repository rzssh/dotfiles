if set -q HERDR_ENV; and not set -q AI_PROFILE_LOADED
    set -l profile (ai-workspace --current-profile)
    if test $status -eq 0
        for key in (ai-run --profile-keys)
            set -e $key
        end
        set -l profile_env (ai-run "$profile" -- env -0 | string split0)
        set -l loaded_profile
        for assignment in $profile_env
            set -l pair (string split -m 1 = -- "$assignment")
            if test (count $pair) -eq 2
                set -gx $pair[1] $pair[2]
                if test "$pair[1]" = AI_PROFILE
                    set loaded_profile $pair[2]
                end
            end
        end
        if test "$loaded_profile" = "$profile"
            set -gx AI_PROFILE_LOADED 1
            if set -q HERDR_WORKSPACE_ID
                ai-workspace --bind-profile "$HERDR_WORKSPACE_ID" "$profile"
            end
        end
    end
end

function pi
    if set -q AI_PROFILE_LOADED
        command pi $argv
    else
        ai-run -- pi $argv
    end
end

function codex
    if set -q AI_PROFILE_LOADED
        command codex $argv
    else
        ai-run -- codex $argv
    end
end

function claude
    if set -q AI_PROFILE_LOADED
        command claude $argv
    else
        ai-run -- claude $argv
    end
end

function opencode
    if set -q AI_PROFILE_LOADED
        command opencode $argv
    else
        ai-run -- opencode $argv
    end
end
