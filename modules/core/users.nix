{ pkgs, vars, ... }:

{
  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.username;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
      "audio"
      "dialout"
    ];
    shell = pkgs.fish;
    initialPassword = vars.username;
  };

  programs.fish.enable = true;
}
