{ pkgs, ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings.LE = {
    MinConnectionInterval = 6;
    MaxConnectionInterval = 6;
    ConnectionLatency = 0;
  };
  boot.extraModprobeConfig = "options btusb enable_autosuspend=n";
  services.blueman.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="2357", ATTR{idProduct}=="0604", ATTR{authorized}="0"
  '';

  systemd.services.dms-bluetooth-resume = {
    description = "Restart DankMaterialShell on resume to re-bind the Bluetooth adapter";
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "razen";
      Environment = "XDG_RUNTIME_DIR=/run/user/1000";
      ExecStart = "${pkgs.bash}/bin/sh -c 'sleep 4; ${pkgs.systemd}/bin/systemctl --user restart dms.service'";
    };
  };
}
