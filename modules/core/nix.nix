{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.max-jobs = 8;
  nix.settings.cores = 0;
  nix.settings.auto-optimise-store = true;

  nix.settings.extra-substituters = [
    "https://nix-community.cachix.org"
    "https://cuda-maintainers.cachix.org"
  ];
  nix.settings.extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
  ];

  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  programs.nh = {
    enable = true;
    flake = "/home/razen/projects/dotfiles";
    clean.enable = true;
    clean.extraArgs = "--keep 5 --keep-since 4d";
  };
}
