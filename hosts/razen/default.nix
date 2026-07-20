{ vars, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  networking.hostName = vars.hostname;
  i18n.defaultLocale = vars.locale;
  i18n.extraLocaleSettings.LC_TIME = "en_GB.UTF-8";

  system.stateVersion = "25.05";
}
