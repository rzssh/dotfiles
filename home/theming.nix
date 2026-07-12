{ pkgs, ... }:

{
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };

  gtk = {
    enable = true;
    font = {
      name = "Noto Sans";
      size = 10;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme.name = "Matugen-Mono";
    gtk4.theme = null;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk3.extraCss = ''@import url("matugen.css");'';
    gtk4.extraCss = ''@import url("matugen.css");'';
  };

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
    style.package = pkgs.kdePackages.breeze;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    monospace-font-name = "Monaspace Argon 10";
  };
}
