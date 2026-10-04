{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule {
  pname = "zmk-vim-mode";
  version = "1.0.0-unstable-2026-10-03";

  src = fetchFromGitHub {
    owner = "rzssh";
    repo = "zmk-vim-mode";
    rev = "34a8dd2187c6335f5890c1b5c43fabdfac75ac86";
    hash = "sha256-Hziq0NZKAWpkRbWNf5Dscblw7IaBoXWelqiWoxlOrxM=";
  };

  vendorHash = null;
  subPackages = [ "cmd/zmk-vim-mode" ];
  ldflags = [
    "-s"
    "-w"
    "-X main.Version=0-unstable"
  ];

  meta = {
    description = "Sync keyboard behavior with editor Vim mode";
    homepage = "https://github.com/rzssh/zmk-vim-mode";
    license = lib.licenses.mit;
    mainProgram = "zmk-vim-mode";
  };
}
