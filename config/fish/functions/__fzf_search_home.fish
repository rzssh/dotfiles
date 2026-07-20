function __fzf_search_home --description "Search files from home directory with smart preview"
    # Smart preview script
    set -l preview_script 'bash -c \'
        if [ -d "{}" ]; then
            eza --tree --level=2 --icons --all --color=always --group-directories-first "{}"
        elif [ -f "{}" ]; then
            bat --color=always --style=numbers,changes --line-range=:500 "{}" 2>/dev/null || cat "{}"
        fi
    \''

    set -l selected (
        fd --type f --type d --hidden --follow --exclude .git --exclude node_modules . ~ 2>/dev/null |
        fzf \
            --prompt "🏠  Home> " \
            --header "ALT-F: files | ALT-D: dirs | ALT-A: all | CTRL-Y: copy | ENTER: open" \
            --preview "$preview_script" \
            --preview-window "right:60%:wrap:border-left" \
            --border-label=" Search from Home " \
            --bind "ctrl-/:toggle-preview" \
            --bind "ctrl-d:half-page-down" \
            --bind "ctrl-u:half-page-up" \
            --bind "alt-f:change-prompt(📄  Files> )+reload(fd --type f --hidden --follow --exclude .git --exclude node_modules . ~)" \
            --bind "alt-d:change-prompt(📁  Dirs> )+reload(fd --type d --hidden --follow --exclude .git --exclude node_modules . ~)" \
            --bind "alt-a:change-prompt(🏠  Home> )+reload(fd --type f --type d --hidden --follow --exclude .git --exclude node_modules . ~)" \
            --bind "ctrl-y:execute-silent(printf %s {} | wl-copy)"
    )

    if test -n "$selected"
        if test -d "$selected"
            # If directory, cd into it
            cd "$selected"
            commandline -f repaint
        else
            # If file, cd to its directory then open it
            set -l dir (dirname "$selected")
            set -l file (basename "$selected")
            cd "$dir" && $EDITOR "$file"
            commandline -f repaint
        end
    end
end
