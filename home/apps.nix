{ pkgs, inputs, ... }:

let
  localPkgs = import ../pkgs { inherit pkgs; };
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
in
{
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
    obsidian
    inputs.zen-browser.packages.x86_64-linux.default
    inputs.helium.packages.x86_64-linux.default
    pear-desktop
    libreoffice-qt6-fresh
    gimp
    krita

    # cad & 3d printing
    blender
    freecad
    kicad
    openscad-unstable
    bambuPkgs.bambu-studio

    # theming
    papirus-icon-theme
    gtk3
    gtk4
  ];
}
