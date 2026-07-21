{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 5;
  };
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  boot.tmp.cleanOnBoot = true;
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  zramSwap.enable = true;

  environment.systemPackages = [ pkgs.sbctl ];
}
