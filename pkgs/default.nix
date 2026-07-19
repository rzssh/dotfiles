{ pkgs, inputs }:
let
  llamaPkgs = import inputs.nixpkgs-llamacpp {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  babysitter = pkgs.callPackage ./babysitter/package.nix { };
  figlet = pkgs.callPackage ./figlet/package.nix { };
  hyprwhspr = llamaPkgs.callPackage ./hyprwhspr/package.nix { };
  llama-cpp-cuda = llamaPkgs.llama-cpp.override { cudaSupport = true; };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent/package.nix {
    src = inputs.pi-coding-agent-src;
  };
  qmk-hid-host = pkgs.callPackage ./qmk-hid-host/package.nix { };
  wl-kbptr = pkgs.callPackage ./wl-kbptr/package.nix { };
}
