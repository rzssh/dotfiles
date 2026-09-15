{ pkgs, ... }:

{
  security.polkit.enable = true;
  programs.fuse.enable = true;
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.brlaser ];
  hardware.printers.ensurePrinters = [
    {
      name = "Brother_HL-L1232W";
      location = "Network";
      deviceUri = "ipp://192.168.0.30/ipp/print";
      model = "drv:///brlaser.drv/brl1232.ppd";
      ppdOptions.PageSize = "A4";
    }
  ];
  hardware.printers.ensureDefaultPrinter = "Brother_HL-L1232W";
  services.automatic-timezoned.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gnome.at-spi2-core.enable = true;
  services.accounts-daemon.enable = true;
  services.udisks2.enable = true;
  programs.solaar = {
    enable = true;
    userService.enable = true;
    userService.window = "hide";
  };
}
