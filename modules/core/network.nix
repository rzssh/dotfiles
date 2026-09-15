{
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;

  networking.networkmanager.settings.connection = {
    "ethernet.cloned-mac-address" = "preserve";
    "wifi.autoconnect" = "no";
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0
    options iwlmvm power_scheme=1
  '';
}
