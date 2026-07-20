if set -q HERDR_ENV
    set -l profile (ai-workspace --current-profile)
    if test $status -eq 0
        set -l workspace_env (ai-run --workspace-env "$profile" | string split0)
        for assignment in $workspace_env
            set -l pair (string split -m 1 = -- "$assignment")
            if test (count $pair) -eq 2
                set -gx $pair[1] $pair[2]
            end
        end
        if set -q HERDR_WORKSPACE_ID
            ai-workspace --set-profile "$HERDR_WORKSPACE_ID" "$profile" "$PWD"
        end
    end
end

function __ai_workspace_refresh --on-event fish_postexec
    if set -q HERDR_ENV HERDR_WORKSPACE_ID
        command ai-workspace --refresh-metadata "$HERDR_WORKSPACE_ID" "$PWD" >/dev/null 2>&1
    end
end
