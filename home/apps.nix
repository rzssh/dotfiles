{ pkgs, inputs, lib, ... }:

let
  localPkgs = import ../pkgs { inherit pkgs inputs; };
  vimiumId = "{d7742d87-e61d-4b78-b8a1-b469842139fa}";
  vimiumSettings = {
    linkHintCharacters = "shtaregyniwfdo";
    ignoreKeyboardLayout = true;
  };
  vimiumSettingsJson = builtins.toJSON vimiumSettings;
  zenTabShortcuts = pkgs.writeText "zen-tab-shortcuts.js" ''
    (() => {
      document.addEventListener("command", event => {
        const match = /^key_selectTab([1-8])$/.exec(event.target.id);
        if (!match && event.target.id !== "key_selectLastTab") return;
        event.preventDefault();
        event.stopImmediatePropagation();
        const tabs = gBrowser.visibleTabs.filter(
          tab => !tab.pinned && !tab.hasAttribute("zen-glance-tab")
        );
        if (!tabs.length) return;
        const index = match ? Number(match[1]) - 1 : tabs.length - 1;
        gBrowser.selectedTab = tabs[Math.min(index, tabs.length - 1)];
      }, true);
    })();
  '';
  zenAutoConfig = pkgs.writeText "zen-tab-shortcuts.cfg" ''
    //
    (() => {
      try {
        const observerService = Components.classes["@mozilla.org/observer-service;1"]
          .getService(Components.interfaces.nsIObserverService);
        const scriptLoader = Components.classes["@mozilla.org/moz/jssubscript-loader;1"]
          .getService(Components.interfaces.mozIJSSubScriptLoader);
        observerService.addObserver({
          observe(browserWindow) {
            try {
              scriptLoader.loadSubScript("file://${zenTabShortcuts}", browserWindow);
            } catch (error) {
              Components.utils.reportError(error);
            }
          }
        }, "browser-delayed-startup-finished");
      } catch (error) {
        Components.utils.reportError(error);
      }
    })();
  '';
  zenAutoConfigPrefs = pkgs.writeText "zen-tab-shortcuts-autoconfig.js" ''
    pref("general.config.filename", "zen-tab-shortcuts.cfg");
    pref("general.config.obscure_value", 0);
    pref("general.config.sandbox_enabled", false);
  '';
  zenUnwrapped = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta-unwrapped.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      lib_dir="$out/lib/zen-bin-${old.version}"
      chmod u+w "$lib_dir" "$lib_dir/defaults" "$lib_dir/defaults/pref"
      install -Dm444 ${zenAutoConfigPrefs} "$lib_dir/defaults/pref/zen-tab-shortcuts-autoconfig.js"
      install -Dm444 ${zenAutoConfig} "$lib_dir/zen-tab-shortcuts.cfg"
    '';
  });
  zen = pkgs.wrapFirefox zenUnwrapped {
    icon = "zen-browser";
    extraPolicies.ExtensionSettings.${vimiumId} = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
      installation_mode = "normal_installed";
    };
  };
  bambuPkgs = import inputs.nixpkgs-bambu {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
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
  tuxedoLatest = pkgs.rustPlatform.buildRustPackage rec {
    pname = "tuxedo";
    version = "2026.7.1";
    src = pkgs.fetchFromGitHub {
      owner = "rzssh";
      repo = "tuxedo";
      rev = "46d0ce47b2a22a4298f47dbcac0a4036d1bc80e4";
      hash = "sha256-KQraBkSV8cOb+BenptuytszGChyPTIPkTXi6qpzqns8=";
    };
    cargoLock.lockFile = "${src}/Cargo.lock";
    nativeCheckInputs = [ pkgs.writableTmpDirAsHomeHook ];
    postPatch = ''
      substituteInPlace src/note.rs src/app/mutations.rs \
        --replace-fail 'projects/tuxedo-tasks' 'task-details'
      substituteInPlace src/main.rs \
        --replace-fail 'open_path_in_editor(&path)?;' 'open_path_in_editor(&path)?;
                        terminal.clear()?;'
    '';
  };
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
    helix
    yazi
    starship
    fishPlugins.autopair
    zoxide
    fzf
    jq
    just
    tuxedoLatest

    # cli utils
    eza
    bat
    fd
    ripgrep
    fx
    tealdeer
    localPkgs.figlet
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
    odin
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
    ols
    zls
    gopls
    vscode-js-debug

    # wayland & desktop utils
    playerctl
    libnotify
    brightnessctl
    pavucontrol
    wl-clip-persist
    wf-recorder
    slurp
    hyprpicker
    wayscriber
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
    thunderbird
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
