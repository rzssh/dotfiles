{ pkgs, inputs, lib, ... }:

let
  localPkgs = import ../pkgs { inherit pkgs; };
  vimiumId = "{d7742d87-e61d-4b78-b8a1-b469842139fa}";
  vimiumSettings = {
    linkHintCharacters = "shtaregyniwfdo";
    ignoreKeyboardLayout = true;
  };
  vimiumSettingsJson = builtins.toJSON vimiumSettings;
  zen = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    extraPolicies.ExtensionSettings.${vimiumId} = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
      installation_mode = "normal_installed";
    };
  };
  bambuPkgs = import inputs.nixpkgs-bambu {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  llamaPkgs = import inputs.nixpkgs-llamacpp {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ../patches/herdr/current-workspace-agent-panel.patch ];
  });
  vesktop =
    if pkgs.vesktop.version == "1.6.5" then
      (pkgs.vesktop.override { electron_40 = pkgs.electron_41-bin; }).overrideAttrs {
        preBuild = ''
          cp -r ${pkgs.electron_41-bin.dist} electron-dist
          chmod -R u+w electron-dist
        '';
      }
    else
      throw "Recheck Vesktop Electron workaround in home/apps.nix";
in
{
  home.activation.vimiumSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for db in "$HOME"/.zen/*/storage-sync-v2.sqlite "$HOME"/.config/zen/*/storage-sync-v2.sqlite; do
      [ -f "$db" ] || continue
      ${pkgs.sqlite}/bin/sqlite3 "$db" <<'SQL'
.timeout 5000
INSERT INTO storage_sync_data (ext_id, data, sync_change_counter)
VALUES ('${vimiumId}', '${vimiumSettingsJson}', 1)
ON CONFLICT (ext_id) DO UPDATE SET
  data = json_patch(COALESCE(storage_sync_data.data, '{}'), '${vimiumSettingsJson}'),
  sync_change_counter = storage_sync_data.sync_change_counter + 1
WHERE json_extract(storage_sync_data.data, '$.linkHintCharacters') IS NOT '${vimiumSettings.linkHintCharacters}'
   OR json_extract(storage_sync_data.data, '$.ignoreKeyboardLayout') IS NOT 1;
SQL
    done
  '';

  home.packages = with pkgs; [
    # shell & terminal
    ghostty
    tmux
    helix
    yazi
    starship
    fishPlugins.autopair
    zoxide
    sesh
    fzf
    jq
    just
    tuxedo
    herdr

    # cli utils
    eza
    bat
    fd
    ripgrep
    fx
    tealdeer
    gdu
    gnupg
    unzip
    (p7zip.override { enableUnfree = true; })
    imagemagick
    ghostscript
    poppler-utils
    bubblewrap
    nix-search-tv

    # git & dev workflow
    jujutsu
    jjui
    lazygit
    gh
    gh-dash
    delta
    difftastic
    mergiraf
    lazydocker
    dblab

    # secrets
    age
    sops

    # languages & build
    gcc
    gnumake
    python3
    nodejs_24
    uv
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
    zig
    go
    typst
    tree-sitter

    # lsps, formatters, debug
    nixd
    lua-language-server
    stylua
    vtsls
    typescript-go
    vscode-langservers-extracted
    biome
    prettierd
    tailwindcss-language-server
    marksman
    yaml-language-server
    fish-lsp
    hyprls
    pyright
    typos-lsp
    tinymist
    bash-language-server
    zls
    gopls
    vscode-js-debug

    # ai
    localPkgs.agentmemory
    localPkgs.pi-coding-agent
    (llamaPkgs.llama-cpp.override { cudaSupport = true; })
    opencode
    inputs.hermes-agent.packages.x86_64-linux.default

    # wayland & desktop utils
    playerctl
    libnotify
    brightnessctl
    pavucontrol
    wl-clip-persist
    wf-recorder
    slurp
    hyprpicker
    matugen
    satty
    localPkgs.hyprwhspr
    localPkgs.qmk-hid-host
    localPkgs.wl-kbptr
    xdg-utils

    # system & hardware
    psmisc
    usbutils

    # media & downloads
    yt-dlp
    qbittorrent
    vlc
    qimgv
    loupe

    # kde integration & thumbnails
    kdePackages.okular
    kdePackages.ark
    kdePackages.kio-admin
    kdePackages.kservice
    kdePackages.ffmpegthumbs
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kimageformats
    qt6.qtimageformats

    # gui apps
    vesktop
    telegram-desktop
    slack
    obsidian
    zen
    inputs.helium.packages.x86_64-linux.default
    pear-desktop
    libreoffice-qt6-fresh
    gimp
    krita

    # cad & 3d printing
    blender
    bambuPkgs.freecad
    kicad
    openscad-unstable
    bambuPkgs.bambu-studio

    # theming
    papirus-icon-theme
    gtk3
    gtk4
  ];
}
