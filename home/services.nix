{
  config,
  pkgs,
  inputs,
  ...
}:

let
  localPkgs = import ../pkgs { inherit pkgs inputs; };
  dots = "/home/razen/projects/dotfiles";
  graphical = desc: exec: {
    Unit = {
      Description = desc;
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = exec;
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
in
{
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-qt;
  };

  systemd.user.settings.Manager.DefaultTimeoutStopSec = "5s";

  systemd.user.services = {
    herdr-config-sync = {
      Unit.Description = "Generate Herdr config";
      Service = {
        Type = "oneshot";
        ExecStart = "${dots}/bin/theme/herdr";
      };
    };
    polkit-kde-agent = graphical "KDE polkit authentication agent" "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
    plasma-kactivitymanagerd = {
      Unit = {
        Description = "KDE activity manager";
        Before = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.kdePackages.kactivitymanagerd}/libexec/kactivitymanagerd";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
    hyprwhspr = graphical "hyprwhspr speech-to-text daemon" "${localPkgs.hyprwhspr}/bin/hyprwhspr";
    qmk-hid-host = graphical "QMK/ZMK raw HID status widget host" "${localPkgs.qmk-hid-host}/bin/qmk-hid-host -c ${config.xdg.configHome}/qmk-hid-host/config.json";
    solaar = graphical "Logitech device manager" "${pkgs.solaar}/bin/solaar --window=hide";
    arrpc = graphical "arRPC Discord rich presence bridge" "${pkgs.arrpc}/bin/arrpc";
  };

  systemd.user.paths.herdr-config-sync = {
    Unit.Description = "Watch Herdr config";
    Path = {
      PathChanged = "${dots}/config/herdr/config.toml";
      Unit = "herdr-config-sync.service";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
