{
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;

  networking.networkmanager.settings.connection = {
    "ethernet.cloned-mac-address" = "preserve";
    "wifi.autoconnect" = "no";
  };

  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 172.16.0.0/12 -m multiport --dports 8012,8013,8014 -j nixos-fw-accept
  '';

  boot.extraModprobeConfig = ''
    options iwlwifi bt_coex_active=0 power_save=0
    options iwlmvm power_scheme=1
  '';
}
