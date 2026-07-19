{ config, pkgs, inputs, lib, ... }:

let
  dots = "/home/razen/projects/dotfiles";
  link = p: config.lib.file.mkOutOfStoreSymlink "${dots}/${p}";
in
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dank-calendar.homeModules.dank-calendar
    inputs.nix-index-database.homeModules.nix-index
    ./nvim-treesitter.nix
    ./theming.nix
    ./services.nix
    ./desktop.nix
    ./apps.nix
    ./agents.nix
  ];

  home.username = "razen";
  home.homeDirectory = "/home/razen";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    TODO_DIR = "$HOME/notes";
    TODO_FILE = "$HOME/notes/todo.txt";
    DONE_FILE = "$HOME/notes/done.txt";
    TUXEDO_NO_UPDATE_CHECK = "1";
  };

  home.activation.tuxedoFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/notes"
    for file in todo.txt done.txt inbox.txt; do
      [ -e "$HOME/notes/$file" ] || : > "$HOME/notes/$file"
    done
  '';

  home.activation.mutableConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    json_overlay() {
      source=$1
      target=$2
      directory="$(${pkgs.coreutils}/bin/dirname "$target")"
      ${pkgs.coreutils}/bin/mkdir -p "$directory"
      ${pkgs.coreutils}/bin/chmod 700 "$directory"
      current="$(${pkgs.coreutils}/bin/mktemp "$directory/.current.XXXXXX")"
      merged="$(${pkgs.coreutils}/bin/mktemp "$directory/.merged.XXXXXX")"
      if [ -e "$target" ]; then
        ${pkgs.coreutils}/bin/cp -L "$target" "$current"
      else
        printf '{}\n' > "$current"
      fi
      ${pkgs.jq}/bin/jq -e 'type == "object"' "$current" >/dev/null
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$current" "$source" > "$merged"
      ${pkgs.coreutils}/bin/chmod 600 "$merged"
      ${pkgs.coreutils}/bin/mv -f "$merged" "$target"
      ${pkgs.coreutils}/bin/rm -f "$current"
    }

    btop_overlay() {
      source=$1
      target=$2
      directory="$(${pkgs.coreutils}/bin/dirname "$target")"
      ${pkgs.coreutils}/bin/mkdir -p "$directory"
      ${pkgs.coreutils}/bin/chmod 700 "$directory"
      current="$(${pkgs.coreutils}/bin/mktemp "$directory/.current.XXXXXX")"
      merged="$(${pkgs.coreutils}/bin/mktemp "$directory/.merged.XXXXXX")"
      if [ -e "$target" ]; then
        ${pkgs.coreutils}/bin/cp -L "$target" "$current"
      else
        : > "$current"
      fi
      ${pkgs.gawk}/bin/awk '
        NR == FNR {
          if (match($0, /^[A-Za-z0-9_]+/)) {
            key = substr($0, RSTART, RLENGTH)
            managed[key] = $0
            order[++count] = key
          }
          next
        }
        {
          if (match($0, /^[A-Za-z0-9_]+[[:space:]]*=/)) {
            key = substr($0, RSTART, RLENGTH)
            sub(/[[:space:]]*=$/, "", key)
            if (key in managed) {
              if (!seen[key]++) print managed[key]
              next
            }
          }
          print
        }
        END {
          for (i = 1; i <= count; i++) {
            key = order[i]
            if (!seen[key]) print managed[key]
          }
        }
      ' "$source" "$current" > "$merged"
      ${pkgs.coreutils}/bin/chmod 600 "$merged"
      ${pkgs.coreutils}/bin/mv -f "$merged" "$target"
      ${pkgs.coreutils}/bin/rm -f "$current"
    }

    json_overlay "${dots}/config/dms/settings.json" "$HOME/.config/DankMaterialShell/settings.json"
    json_overlay "${dots}/config/dms/plugin-settings.json" "$HOME/.config/DankMaterialShell/plugin_settings.json"
    btop_overlay "${dots}/config/btop.defaults.conf" "$HOME/.config/btop/btop.conf"
    herdr_directory="$HOME/.config/herdr"
    ${pkgs.coreutils}/bin/mkdir -p "$herdr_directory"
    ${pkgs.coreutils}/bin/chmod 700 "$herdr_directory"
    herdr_config="$(${pkgs.coreutils}/bin/mktemp "$herdr_directory/.config.XXXXXX")"
    ${pkgs.coreutils}/bin/install -m600 "${dots}/config/herdr/config.toml" "$herdr_config"
    ${pkgs.coreutils}/bin/mv -f "$herdr_config" "$herdr_directory/config.toml"
    ${pkgs.python3}/bin/python3 "${dots}/bin/theme/herdr"
  '';

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    enableSystemMonitoring = true;
    enableDynamicTheming = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;
    managePluginSettings = false;
    plugins.dankKDEConnect.src = "${inputs.dms-plugins}/DankKDEConnect";
  };

  programs.dank-calendar = {
    enable = true;
    systemd.enable = true;
  };

  systemd.user.services.dcal.Service.ExecStart = lib.mkForce "${lib.getExe config.programs.dank-calendar.package} daemon";

  programs.git.enable = true;

  programs.fish = {
    enable = true;
    generateCompletions = false;
    shellInit = "source ${dots}/config/fish/config.fish";
  };

  programs.nix-index-database.comma.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    extraConfig.PROJECTS = "$HOME/projects";
  };

  xdg.configFile = {
    "nvim".source = link "config/nvim";
    "fish/conf.d".source = link "config/fish/conf.d";
    "fish/functions".source = link "config/fish/functions";
    "ghostty/config".source = link "config/ghostty/config";
    "ghostty/themes/dankcolors".source = link "config/ghostty/themes/dankcolors";
    "yazi/keymap.toml".source = link "config/yazi/keymap.toml";
    "yazi/theme.toml".source = link "config/yazi/theme.toml";
    "yazi/yazi.toml".source = link "config/yazi/yazi.toml";
    "lazydocker".source = link "config/lazydocker";
    "lazygit".source = link "config/lazygit";
    "jj/config.toml".source = link "config/jj/config.toml";
    "gh/config.yml".source = link "config/gh/config.yml";
    "gh-dash".source = link "config/gh-dash";
    "herdr/plugins/focus-notify".source = link "config/herdr/plugins/focus-notify";
    "starship.toml".source = link "config/starship.toml";
    "matugen".source = link "config/matugen";
    "qmk-hid-host/config.json".text = builtins.toJSON {
      devices = [
        {
          name = "charybdis dgl";
          productId = "0x615e";
        }
      ];
      layouts = [
        "EN"
        "RU"
        "UA"
      ];
      reconnectDelay = 1000;
    };
    "hypr/hyprland.lua".source = link "config/hypr/hyprland.lua";
    "hypr/xdph.conf".source = link "config/hypr/xdph.conf";
    "hypr/scripts".source = link "config/hypr/scripts";
    "menus/applications.menu".text = ''
      <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
      <Menu>
        <Name>Applications</Name>
        <DefaultAppDirs/>
        <DefaultDirectoryDirs/>
        <Include><All/></Include>
      </Menu>
    '';
  };

  xdg.configFile."vesktop-flags.conf".text = ''
--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiVideoDecoder,WaylandWindowDecorations,UseOzonePlatform,WebRTCPipeWireCapturer
--ozone-platform=wayland
--enable-gpu-rasterization
--enable-zero-copy
--ignore-gpu-blocklist
--enable-hardware-overlays
--disable-gpu-driver-bug-workarounds
--use-gl=angle
--force-device-scale-factor=1.10
  '';

  home.file = {
    ".gitconfig".source = link "home/files/.gitconfig";
    ".editorconfig".source = link "home/files/.editorconfig";
    ".npmrc".source = link "home/files/.npmrc";
    ".rgignore".source = link "home/files/.rgignore";
    ".gitignore_global".source = link "home/files/.gitignore_global";
    ".gitattributes_global".source = link "home/files/.gitattributes_global";
    ".dblab.yaml".source = link "home/files/.dblab.yaml";
    ".local/bin/wallpaper-state".source = link "bin/wallpaper-state";
    ".local/bin/ns".source = link "bin/ns";
    ".local/bin/herdr-jj-workspace".source = link "bin/herdr-jj-workspace";
    ".local/bin/herdr-move-tab-workspace".source = link "bin/herdr-move-tab-workspace";
    ".local/bin/theme-terminals".source = link "bin/theme/terminals";
    ".local/bin/theme-gtk".source = link "bin/theme/gtk";
    ".local/bin/theme-hyprland".source = link "bin/theme/hyprland";
    ".local/bin/theme-herdr".source = link "bin/theme/herdr";
    ".local/bin/theme-kde".source = link "bin/theme/kde";
    ".local/bin/theme-zen".source = link "bin/theme/zen";
    ".local/bin/theme-telegram".source = link "bin/theme/telegram";
    ".local/bin/theme-icons".source = link "bin/theme/icons";
    ".local/bin/theme-vesktop".source = link "bin/theme/vesktop";
    ".local/share/kio/servicemenus/admin-folder.desktop".source = link "home/files/kio/admin-folder.desktop";
    ".local/share/kio/servicemenus/print.desktop".source = link "home/files/kio/print.desktop";
  };
}
