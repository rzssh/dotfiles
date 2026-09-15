{
  pkgs,
  inputs,
  lib,
  ...
}:

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
      const classes = Components.classes;
      const interfaces = Components.interfaces;
      const chromeDir = classes["@mozilla.org/file/directory_service;1"]
        .getService(interfaces.nsIProperties)
        .get("UChrm", interfaces.nsIFile);
      const io = classes["@mozilla.org/network/io-service;1"]
        .getService(interfaces.nsIIOService);
      const styleSheets = classes["@mozilla.org/content/style-sheet-service;1"]
        .getService(interfaces.nsIStyleSheetService);
      const chromeFile = chromeDir.clone();
      const contentFile = chromeDir.clone();
      chromeFile.append("userChrome.css");
      contentFile.append("userContent.css");
      const chromeUri = io.newFileURI(chromeFile);
      const contentUri = io.newFileURI(contentFile);
      let chromeVersion;
      let contentVersion;

      const version = file => file.exists()
        ? file.lastModifiedTime + ":" + file.fileSize
        : null;

      const reloadStyles = () => {
        const nextChromeVersion = version(chromeFile);
        if (nextChromeVersion && nextChromeVersion !== chromeVersion) {
          if (chromeVersion) {
            windowUtils.removeSheet(chromeUri, windowUtils.USER_SHEET);
          }
          windowUtils.loadSheet(chromeUri, windowUtils.USER_SHEET);
          chromeVersion = nextChromeVersion;
        }

        const nextContentVersion = version(contentFile);
        if (nextContentVersion && nextContentVersion !== contentVersion) {
          if (styleSheets.sheetRegistered(contentUri, styleSheets.USER_SHEET)) {
            styleSheets.unregisterSheet(contentUri, styleSheets.USER_SHEET);
          }
          styleSheets.loadAndRegisterSheet(contentUri, styleSheets.USER_SHEET);
          contentVersion = nextContentVersion;
        }
      };

      reloadStyles();
      const styleTimer = setInterval(reloadStyles, 1000);
      addEventListener("unload", () => clearInterval(styleTimer), { once: true });
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
  zenUnwrapped =
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta-unwrapped.overrideAttrs
      (old: {
        postInstall = (old.postInstall or "") + ''
          lib_dir="$out/lib/zen-bin-${old.version}"
          omni="$lib_dir/browser/omni.ja"
          work_dir=$(mktemp -d)
          chmod u+w "$omni"
          ${pkgs.unzip}/bin/unzip -q "$omni" -d "$work_dir" || [ $? = 2 ]
          browser_sets="$work_dir/chrome/browser/content/browser/browser-sets.js"
          ${pkgs.python3}/bin/python - "$browser_sets" <<'PY'
          from pathlib import Path
          import sys

          path = Path(sys.argv[1])
          source = path.read_text()
          numbered = """          let index = event.target.id.at(-1) - 1;
                    gBrowser.selectTabAtIndex(index, {
                      event,
                      metricsContext: gBrowser.TabMetrics.userTriggeredContext(
                        gBrowser.TabMetrics.METRIC_SOURCE.KEYBOARD
                      ),
                    });"""
          numbered_unpinned = """          const tabs = gBrowser.visibleTabs.filter(
                      tab => !tab.pinned && !tab.hasAttribute(\"zen-glance-tab\")
                    );
                    const index = event.target.id.at(-1) - 1;
                    gBrowser.selectedTab =
                      tabs[Math.min(index, tabs.length - 1)] ?? gBrowser.selectedTab;"""
          last = """          gBrowser.selectTabAtIndex(-1, {
                      event,
                      metricsContext: gBrowser.TabMetrics.userTriggeredContext(
                        gBrowser.TabMetrics.METRIC_SOURCE.KEYBOARD
                      ),
                    });"""
          last_unpinned = """          gBrowser.selectedTab =
                      gBrowser.visibleTabs.findLast(
                        tab => !tab.pinned && !tab.hasAttribute(\"zen-glance-tab\")
                      ) ?? gBrowser.selectedTab;"""
          if source.count(numbered) != 1 or source.count(last) != 1:
              raise SystemExit("Zen tab shortcut source changed")
          path.write_text(source.replace(numbered, numbered_unpinned).replace(last, last_unpinned))
          PY
          patched_omni="$work_dir.patched"
          (cd "$work_dir" && ${pkgs.zip}/bin/zip -0qr "$patched_omni" .)
          cp "$patched_omni" "$omni"
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
    wezterm
    helix
    yazi
    aerc
    starship
    fishPlugins.autopair
    zoxide
    fzf
    jq
    just
    inputs.tuxedo.packages.${pkgs.stdenv.hostPlatform.system}.default

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
    gocryptfs
    attr
    rsync
    unzip
    (p7zip.override { enableUnfree = true; })
    imagemagick
    ghostscript
    poppler-utils
    (tesseract.override { enableLanguages = [ "eng" "rus" "ukr" ]; })
    bubblewrap
    nix-search-tv

    # git & dev workflow
    lazygit
    git-remote-gcrypt
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
    localPkgs.llama-cpp-cuda
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
    pulseaudio
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
    losslesscut
    qimgv
    loupe

    # kde integration & thumbnails
    kdePackages.okular
    kdePackages.ark
    kdePackages.kdialog
    kdePackages.kservice
    kdePackages.ffmpegthumbs
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kimageformats
    qt6.qtimageformats

    # gui apps
    mailspring
    vesktop
    telegram-desktop
    slack
    zoom-us
    obsidian
    zen
    inputs.helium.packages.x86_64-linux.default
    libreoffice-qt6-fresh
    gimp
    krita

    # cad & 3d printing
    blender
    bambuPkgs.freecad
    kicad
    openscad
    bambuPkgs.bambu-studio

    # theming
    papirus-icon-theme
    gtk3
    gtk4
  ];
}
