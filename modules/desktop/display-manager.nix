{
  config,
  inputs,
  lib,
  vars,
  ...
}:

{
  imports = [ inputs.dank-greeter.nixosModules.default ];

  programs.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/${vars.username}";
  };

  services.greetd.settings.initial_session = lib.mkIf vars.autoLogin {
    command = "${lib.getExe config.programs.uwsm.package} start -e -D Hyprland hyprland.desktop";
    user = vars.username;
  };

  security.pam.services.greetd.enableGnomeKeyring = true;
}
