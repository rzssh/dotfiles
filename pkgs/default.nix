{ pkgs, inputs }:
let
  llamaPkgs = import inputs.nixpkgs-llamacpp {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  figlet = pkgs.callPackage ./figlet/package.nix { };
  hyprwhspr = llamaPkgs.callPackage ./hyprwhspr/package.nix { };
  llama-cpp-cuda = llamaPkgs.llama-cpp.override { cudaSupport = true; };
  qmk-hid-host = pkgs.callPackage ./qmk-hid-host/package.nix { };
  wl-kbptr = pkgs.callPackage ./wl-kbptr/package.nix { };
}
