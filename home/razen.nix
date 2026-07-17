{ config, pkgs, inputs, lib, ... }:

let
  dots = "/home/razen/projects/dotfiles";
  link = p: config.lib.file.mkOutOfStoreSymlink "${dots}/${p}";
  aiProfileFiles = lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".env" name)
    (builtins.readDir ../secrets/ai-profiles);
  aiProfileSecrets = lib.mapAttrs'
    (file: _: let profile = lib.removeSuffix ".env" file; in lib.nameValuePair "ai-profiles/${profile}" {
      sopsFile = ../secrets/ai-profiles + "/${file}";
      format = "dotenv";
      path = "${config.home.homeDirectory}/.local/share/ai/profiles/${profile}/env";
    })
    aiProfileFiles;
in
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.nix-index-database.homeModules.nix-index
    inputs.sops-nix.homeManagerModules.sops
    ./nvim-treesitter.nix
    ./theming.nix
    ./services.nix
    ./desktop.nix
    ./apps.nix
  ];

  home.username = "razen";
  home.homeDirectory = "/home/razen";
  home.stateVersion = "25.05";

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    EDITOR = "nvim";
    AGENTMEMORY_URL = "http://127.0.0.1:3111";
    AI_DEFAULT_PROFILE = "personal";
    CAVEMAN_DEFAULT_MODE = "ultra";
    PONYTAIL_DEFAULT_MODE = "full";
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

  home.activation.piSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings="$HOME/.pi/agent/settings.json"
    source="${dots}/config/ai/pi/settings.json"
    if [ -L "$settings" ] && [ "$(${pkgs.coreutils}/bin/readlink -f "$settings")" = "$source" ]; then
      ${pkgs.coreutils}/bin/rm "$settings"
    fi
    if [ ! -e "$settings" ]; then
      ${pkgs.coreutils}/bin/install -Dm600 "$source" "$settings"
    fi
  '';

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    enableSystemMonitoring = true;
    enableDynamicTheming = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;
  };

  programs.git.enable = true;

  programs.fish = {
    enable = true;
    generateCompletions = false;
    shellInit = "source ${dots}/config/fish/config.fish";
  };

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sops.secrets = aiProfileSecrets;

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
    "fish/completions".source = link "config/fish/completions";
    "fish/conf.d".source = link "config/fish/conf.d";
    "fish/functions".source = link "config/fish/functions";
    "fish/fish_variables".source = link "config/fish/fish_variables";
    "ghostty".source = link "config/ghostty";
    "yazi".source = link "config/yazi";
    "btop".source = link "config/btop";
    "lazydocker".source = link "config/lazydocker";
    "lazygit".source = link "config/lazygit";
    "jj".source = link "config/jj";
    "gh".source = link "config/gh";
    "gh-dash".source = link "config/gh-dash";
    "herdr/config.toml".source = link "config/herdr/config.toml";
    "herdr/plugins/focus-notify".source = link "config/herdr/plugins/focus-notify";
    "opencode".source = link "config/opencode";
    "starship.toml".source = link "config/starship.toml";
    "matugen".source = link "config/matugen";
    "DankMaterialShell".source = link "config/DankMaterialShell";
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
    ".claude/CLAUDE.md".source = link "home/files/claude/CLAUDE.md";
    ".claude/settings.json".source = link "home/files/claude/settings.json";
    ".claude/output-styles".source = link "home/files/claude/output-styles";
    ".config/caveman/config.json".source = link "home/files/caveman/config.json";
    ".codex/AGENTS.md".source = link "home/files/codex/AGENTS.md";
    ".codex/config.toml".source = link "home/files/codex/config.toml";
    ".agents/skills".source = link ".agents/skills";
    ".pi/agent/AGENTS.md".source = link "home/files/codex/AGENTS.md";
    ".pi/agent/APPEND_SYSTEM.md".source = link "home/files/pi/APPEND_SYSTEM.md";
    ".pi/agent/extensions/workspace-sandbox.ts".source = link "home/files/pi/extensions/workspace-sandbox.ts";
    ".pi/agent/settings.defaults.json".source = link "config/ai/pi/settings.json";
    ".hermes/config.yaml".source = link "config/hermes/config.yaml";
    ".agentmemory/.env".text = ''
      AGENTMEMORY_URL=http://127.0.0.1:3111
      AGENTMEMORY_ALLOW_AGENT_SDK=false
      AGENTMEMORY_AUTO_COMPRESS=false
    '';
    ".local/bin/ai-run".source = link "bin/ai-run";
    ".local/bin/ai-workspace".source = link "bin/ai-workspace";
    ".local/bin/ai-workspace-picker".source = link "bin/ai-workspace-picker";
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
