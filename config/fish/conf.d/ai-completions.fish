function __ai_profiles
    set -l root "$HOME/.local/share/ai/profiles"
    if set -q AI_PROFILES_DIR
        set root "$AI_PROFILES_DIR"
    end
    if test -d "$root"
        command find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null
    end
end

function __ai_config_roles
    python3 -c 'import json, os
path = os.environ.get("AI_ROLES_CONFIG", os.path.expanduser("~/.config/ai/roles.json"))
try:
    data = json.load(open(path))
except Exception:
    data = {}
print("\n".join(sorted(data)))' 2>/dev/null
end

function __ai_active_roles
    ai-role list 2>/dev/null | string split \t -f 1
end

function __ai_roles
    begin
        printf '%s\n' lead build review scout
        __ai_config_roles
        __ai_active_roles
    end | sort -u
end

function __ai_swap_targets
    begin
        printf '%s\n' claude codex opencode hermes
        __ai_config_roles
    end | sort -u
end

complete -c ai-pick -f -a 'profile\ set profile\ clear team\ start role\ swap role\ send state\ show'

complete -c ai-profile -f -n '__fish_use_subcommand' -a 'get set clear list scope'
complete -c ai-profile -f -n '__fish_seen_subcommand_from set' -a '(__ai_profiles)'
complete -c ai-profile -f -l workspace -r
complete -c ai-profile -f -l scope -r

complete -c ai-role -f -n '__fish_use_subcommand' -a 'list get set clear scope'
complete -c ai-role -f -n '__fish_seen_subcommand_from get clear' -a '(__ai_roles)'
complete -c ai-role -f -l workspace -r
complete -c ai-role -f -l scope -r

complete -c ai-send -f -n 'test (count (commandline -opc)) -eq 1' -a '(__ai_roles)'

complete -c ai-swap -f -n 'test (count (commandline -opc)) -eq 1' -a '(__ai_roles)'
complete -c ai-swap -f -n 'test (count (commandline -opc)) -eq 2' -a '(__ai_swap_targets)'
complete -c ai-swap -f -l no-handoff

complete -c ai-pi -f -n 'test (count (commandline -opc)) -eq 1' -a '(__ai_config_roles)'

complete -c ai-workspace -f -n 'test (count (commandline -opc)) -eq 1' -a '(__ai_profiles)'
complete -c ai-herdr -f -n 'test (count (commandline -opc)) -eq 1' -a '(__ai_profiles)'

for command in ai-pick ai-profile ai-role ai-send ai-swap ai-pi ai-workspace ai-herdr ai-team ai-handoff ai-exec
    complete -c $command -s h -l help -d help
end
