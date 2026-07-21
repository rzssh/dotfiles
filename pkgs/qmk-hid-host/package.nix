{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  makeWrapper,
  hidapi,
  systemd,
  pulseaudio,
  dbus,
  libx11,
  curl,
  hyprland,
  wireplumber,
}:

rustPlatform.buildRustPackage {
  pname = "qmk-hid-host";
  version = "0-unstable-2026-06-21";

  src = fetchFromGitHub {
    owner = "rzssh";
    repo = "qmk-hid-host";
    rev = "9e61e04e62be73edccc3610c0b35e2d4dc1d379a";
    hash = "sha256-5eI6MbymgtTmNd/d+W/3qjmlsTLmwzfYG7sAFkTKK7k=";
  };

  cargoHash = "sha256-YROU8Qlw004m1C6NViIFaO2ioSAWZvGdJ6aIxHJpdA8=";

  nativeBuildInputs = [
    pkg-config
    cmake
    makeWrapper
  ];

  buildInputs = [
    hidapi
    systemd
    pulseaudio
    dbus
    libx11
  ];

  postInstall = ''
    wrapProgram $out/bin/qmk-hid-host \
      --prefix PATH : ${
        lib.makeBinPath [
          curl
          hyprland
          wireplumber
        ]
      }
  '';

  meta = {
    description = "Host daemon for QMK/ZMK raw HID status widgets";
    homepage = "https://github.com/rzssh/qmk-hid-host";
    license = lib.licenses.mit;
    mainProgram = "qmk-hid-host";
  };
}
