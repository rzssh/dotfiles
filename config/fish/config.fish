#
# ███████╗██╗███████╗██╗  ██╗
# ██╔════╝██║██╔════╝██║  ██║
# █████╗  ██║███████╗███████║
# ██╔══╝  ██║╚════██║██╔══██║
# ██║     ██║███████║██║  ██║
# ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝

if test -d "/run/user/"(id -u)"/hypr"
    set -gx HYPRLAND_INSTANCE_SIGNATURE (ls -t /run/user/(id -u)/hypr/ 2>/dev/null | head -1)
end

starship init fish | source
zoxide init --cmd cd fish | source
fx --comp fish | source

set -U fish_greeting

set -gx SUDO_EDITOR nvim
set -gx EDITOR nvim
set -gx MANPAGER "nvim +Man!"

set -x XDG_CONFIG_HOME "$HOME/.config"
set -x PNPM_HOME "$HOME/.local/share/pnpm"

fish_add_path $PNPM_HOME $PNPM_HOME/bin
fish_add_path "$HOME/.bun/bin"

if test -f ~/.cache/matugen/colors.fish
    source ~/.cache/matugen/colors.fish
end
