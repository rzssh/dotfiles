{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule {
  pname = "zmk-vim-mode";
  version = "0-unstable";

  src = fetchFromGitHub {
    owner = "rafaelromao";
    repo = "zmk-vim-mode";
    rev = "fb0cd49d47e9151644bc32d981bc65d107e66d29";
    hash = "sha256-6XkbP07FP3Ah4pT8as2xS9KItdSZsUr2zYIL+XFAe2c=";
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
    homepage = "https://github.com/rafaelromao/zmk-vim-mode";
    license = lib.licenses.mit;
    mainProgram = "zmk-vim-mode";
  };
}
