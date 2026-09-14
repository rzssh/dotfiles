{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
  makeWrapper,
  wrapGAppsHook4,
  gobject-introspection,
  gtk4,
  gtk4-layer-shell,
  wtype,
  wl-clipboard,
  libnotify,
  pulseaudio,
  ydotool,
  bash,
  cudaSupport ? true,
  cudaPackages,
  cudaCapabilities ? [ "8.9" ],
  autoAddDriverRunpath,
}:

let
  pywhispercpp = python3.pkgs.callPackage ./pywhispercpp.nix {
    inherit
      cudaSupport
      cudaPackages
      cudaCapabilities
      autoAddDriverRunpath
      ;
  };

  pythonEnv = python3.withPackages (ps: [
    pywhispercpp
    ps.sounddevice
    ps.numpy
    ps.soxr
    ps.soundfile
    ps.evdev
    ps.pyperclip
    ps.requests
    ps.websocket-client
    ps.psutil
    ps.pyudev
    ps.pulsectl
    ps.dbus-python
    ps.rich
    ps.jsonschema
    ps.pygobject3
    ps.pycairo
  ]);

  runtimePath = lib.makeBinPath [
    wtype
    wl-clipboard
    libnotify
    pulseaudio
    ydotool
    pythonEnv
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "hyprwhspr";
  version = "1.45.0";

  src = fetchFromGitHub {
    owner = "goodroot";
    repo = "hyprwhspr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-jAUWxTvLNSO636WoE3bY7Ri/KVGjNgRUyQFrl76oysE=";
  };

  nativeBuildInputs = [
    makeWrapper
    wrapGAppsHook4
    gobject-introspection
  ];

  buildInputs = [
    gtk4
    gtk4-layer-shell
  ];

  dontWrapGApps = true;

  postPatch = ''
    substituteInPlace lib/cli.py \
      --replace-fail "return 'unknown'" "return 'v${finalAttrs.version}'"
    substituteInPlace lib/mic_osd/runner.py \
      --replace-fail "'/usr/lib64/libgtk4-layer-shell.so*'," "'${gtk4-layer-shell}/lib/libgtk4-layer-shell.so*',"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/hyprwhspr $out/bin $out/share/systemd/user
    cp -r lib $out/lib/hyprwhspr/lib
    cp -r share $out/lib/hyprwhspr/share

    cat > $out/bin/hyprwhspr <<EOF
    #!${bash}/bin/bash
    export HYPRWHSPR_ROOT="$out/lib/hyprwhspr"
    export PYTHONPATH="$out/lib/hyprwhspr/lib\''${PYTHONPATH:+:\$PYTHONPATH}"
    py="${pythonEnv}/bin/python3"
    cli="$out/lib/hyprwhspr/lib/cli.py"
    case "\$1" in
      -h|--help|help) exec "\$py" "\$cli" --help ;;
      --version) exec "\$py" "\$cli" --version ;;
      test|setup|install|config|waybar|noctalia|systemd|status|model|validate|uninstall|backend|state|mic-osd|keyboard|record|transcribe)
        exec "\$py" "\$cli" "\$@" ;;
    esac
    exec "\$py" "$out/lib/hyprwhspr/lib/main.py" "\$@"
    EOF
    chmod +x $out/bin/hyprwhspr

    substitute config/systemd/hyprwhspr.service $out/share/systemd/user/hyprwhspr.service \
      --replace-fail "ExecStart=/usr/lib/hyprwhspr/bin/hyprwhspr" "ExecStart=$out/bin/hyprwhspr" \
      --replace-fail "Environment=HYPRWHSPR_ROOT=/usr/lib/hyprwhspr" "Environment=HYPRWHSPR_ROOT=$out/lib/hyprwhspr" \
      --replace-fail "/bin/bash" "${bash}/bin/bash"

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/hyprwhspr \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${runtimePath}
  '';

  passthru = {
    inherit pywhispercpp pythonEnv;
  };

  meta = {
    description = "Push-to-talk speech-to-text for Linux desktops using whisper.cpp";
    homepage = "https://github.com/goodroot/hyprwhspr";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "hyprwhspr";
  };
})
