function __herdr_vcs_ref --on-variable PWD
    set -q HERDR_WORKSPACE_ID; or return
    set -l reporter "$HOME/projects/herdr-plugin-jj-workspace/target/release/jj-workspace"
    test -x "$reporter"; or return
    command "$reporter" metadata >/dev/null 2>&1 &
    disown $last_pid 2>/dev/null
end

__herdr_vcs_ref
