{ pkgs, inputs }:
let
  llamaPkgs = import inputs.nixpkgs-llamacpp {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  agentmemory = pkgs.callPackage ./agentmemory/package.nix { };
  hyprwhspr = llamaPkgs.callPackage ./hyprwhspr/package.nix { };
  llama-cpp-cuda = llamaPkgs.llama-cpp.override { cudaSupport = true; };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent/package.nix { };
  qmk-hid-host = pkgs.callPackage ./qmk-hid-host/package.nix { };
  wl-kbptr = pkgs.callPackage ./wl-kbptr/package.nix { };
}
