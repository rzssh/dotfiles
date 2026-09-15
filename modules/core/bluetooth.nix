{ lib, pkgs, ... }:
let
  ax210BluetoothFirmware = pkgs.runCommand "ax210-bluetooth-firmware-23.80.0.3" { } ''
    install -Dm644 ${pkgs.fetchurl {
      url = "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/bf24e495b1a009e926ddc8816580cbbc9e58cb8b/intel/ibt-0041-0041.sfi";
      hash = "sha256-taQgnTOqTgJTMGA2Fyfaqbo0QZr2Ha3hTG82Kq287vA=";
    }} $out/lib/firmware/intel/ibt-0041-0041.sfi
    install -Dm644 ${pkgs.fetchurl {
      url = "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/bf24e495b1a009e926ddc8816580cbbc9e58cb8b/intel/ibt-0041-0041.ddc";
      hash = "sha256-/icpgld+/cKJz+Povtr8pgfAt9bJ3xqrGIDiLvkw0Hc=";
    }} $out/lib/firmware/intel/ibt-0041-0041.ddc
  '';
in
{
  hardware.bluetooth.enable = true;
  boot.extraModprobeConfig = "options btusb enable_autosuspend=n";
  services.blueman.enable = true;

  specialisation.bluetooth-stable.configuration = {
    system.nixos.tags = [ "bluetooth-stable" ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;
  };

  specialisation.bluetooth-firmware-23-80.configuration = {
    system.nixos.tags = [ "bluetooth-fw-23.80" ];
    hardware.firmware = lib.mkBefore [ ax210BluetoothFirmware ];
  };

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
