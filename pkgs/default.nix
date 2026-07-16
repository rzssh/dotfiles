{ pkgs }:
{
  agentmemory = pkgs.callPackage ./agentmemory/package.nix { };
  hyprwhspr = pkgs.callPackage ./hyprwhspr/package.nix { };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent/package.nix { };
  qmk-hid-host = pkgs.callPackage ./qmk-hid-host/package.nix { };
  wl-kbptr = pkgs.callPackage ./wl-kbptr/package.nix { };
}
