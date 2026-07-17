{ config, pkgs, inputs, ... }:

let
  localPkgs = import ../pkgs { inherit pkgs inputs; };
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
  systemd.user.settings.Manager.DefaultTimeoutStopSec = "5s";

  systemd.user.services = {
    agentmemory = {
      Unit.Description = "agentmemory local memory server";
      Service = {
        ExecStart = "${localPkgs.agentmemory}/bin/agentmemory";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "AGENTMEMORY_ALLOW_AGENT_SDK=false"
          "AGENTMEMORY_AUTO_COMPRESS=false"
        ];
      };
      Install.WantedBy = [ "default.target" ];
    };
    polkit-kde-agent = graphical "KDE polkit authentication agent" "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
    hyprwhspr = graphical "hyprwhspr speech-to-text daemon" "${localPkgs.hyprwhspr}/bin/hyprwhspr";
    qmk-hid-host = graphical "QMK/ZMK raw HID status widget host" "${localPkgs.qmk-hid-host}/bin/qmk-hid-host -c ${config.xdg.configHome}/qmk-hid-host/config.json";
    wl-clip-persist = graphical "Keep clipboard contents after the source window closes" "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --all-mime-type-regex '(?i)^(?!(?:image|audio|video|font|model)/).+'";
    solaar = graphical "Logitech device manager" "${pkgs.solaar}/bin/solaar --window=hide";
    arrpc = graphical "arRPC Discord rich presence bridge" "${pkgs.arrpc}/bin/arrpc";
  };
}
