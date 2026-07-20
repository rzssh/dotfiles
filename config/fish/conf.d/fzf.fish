if not command -v fzf >/dev/null
    return
end

set -Ux FZF_DEFAULT_COMMAND "fd -H -E '.git' -E 'node_modules'"

set -Ux FZF_DEFAULT_OPTS "\
--highlight-line --info=inline-right --ansi --layout=reverse --border=rounded \
--color=bg+:#313244,bg:-1,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#F9E2AF,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4 \
--color=preview-border:#6C7086,preview-label:#CDD6F4 \
--bind='ctrl-/:toggle-preview' \
--bind='ctrl-d:half-page-down' \
--bind='ctrl-u:half-page-up'"

set -Ux FZF_CTRL_T_OPTS "\
--walker-skip .git,node_modules \
--no-preview \
--border-label=' Files ' \
--prompt='📄  ' \
--header='ENTER: insert path' \
--bind='ctrl-d:half-page-down' \
--bind='ctrl-u:half-page-up'"

set -Ux FZF_ALT_C_OPTS "\
--walker-skip .git,node_modules \
--preview 'eza --tree --level=2 --icons --all --color=always --group-directories-first {} 2>/dev/null' \
--preview-window 'right:60%:border-left:wrap' \
--border-label=' Directories ' \
--prompt='📁  ' \
--header='CTRL-/: toggle preview' \
--bind='ctrl-/:toggle-preview' \
--bind='ctrl-d:half-page-down' \
--bind='ctrl-u:half-page-up'"

set -Ux FZF_CTRL_R_OPTS "\
--no-preview \
--border-label=' Command History ' \
--prompt='  ' \
--header='CTRL-Y: copy | ENTER: execute' \
--bind='ctrl-y:execute-silent(echo -n {} | sed \"s/^[[:space:]]*[0-9]*[[:space:]]*//\" | wl-copy)+abort' \
--bind='ctrl-d:half-page-down' \
--bind='ctrl-u:half-page-up'"

set -U fzf_fd_opts --hidden --follow --exclude=.git --exclude=node_modules
set -U fzf_preview_dir_cmd eza --tree --level=2 --icons --all --color=always --group-directories-first
set -U fzf_preview_file_cmd bat --color=always --style=numbers,changes --line-range=:500

fzf --fish | source

bind \cq '__fzf_search_home'
if bind -M insert >/dev/null 2>&1
    bind -M insert \cq '__fzf_search_home'
end

bind \cg 'fgit'
if bind -M insert >/dev/null 2>&1
    bind -M insert \cg 'fgit'
end

bind \ef frg
if bind -M insert >/dev/null 2>&1
    bind -M insert \ef frg
end

bind \ex 'fkill; commandline -f repaint'
if bind -M insert >/dev/null 2>&1
    bind -M insert \ex 'fkill; commandline -f repaint'
end
