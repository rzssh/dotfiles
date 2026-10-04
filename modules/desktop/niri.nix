{ pkgs, ... }:

{
  programs.niri = {
    enable = true;
    useNautilus = false;
  };

  environment.systemPackages = [ pkgs.xwayland-satellite ];
}
