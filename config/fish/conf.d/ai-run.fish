if set -q HERDR_ENV
    set -l profile (ai-workspace --current-profile)
    if test $status -eq 0
        for key in (ai-run --profile-keys)
            set -e $key
        end
        set -l workspace_env (ai-run --workspace-env "$profile" | string split0)
        for assignment in $workspace_env
            set -l pair (string split -m 1 = -- "$assignment")
            if test (count $pair) -eq 2
                set -gx $pair[1] $pair[2]
            end
        end
        if set -q HERDR_WORKSPACE_ID
            ai-workspace --bind-profile "$HERDR_WORKSPACE_ID" "$profile" "$PWD"
        end
    end
end
