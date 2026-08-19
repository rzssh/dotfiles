{ config, ... }:

{
  sops.secrets.RESTIC_PASSWORD = { };

  fileSystems."/mnt/shared" = {
    device = "/dev/disk/by-uuid/7BFB-7155";
    fsType = "exfat";
    options = [
      "nofail"
      "x-systemd.automount"
      "uid=1000"
      "gid=100"
      "umask=0077"
    ];
  };

  services.restic.backups.home = {
    initialize = true;
    inhibitsSleep = true;
    repository = "/mnt/shared/Backups/restic";
    passwordFile = config.sops.secrets.RESTIC_PASSWORD.path;
    paths = [
      "/home/razen/projects"
      "/home/razen/Documents"
      "/home/razen/Pictures"
      "/home/razen/.config/sops"
      "/home/razen/.gnupg"
      "/home/razen/.ssh"
      "/home/razen/.local/share/keyrings"
      "/home/razen/.local/share/vaults"
    ];
    exclude = [
      ".cache"
      ".direnv"
      ".next"
      ".qmk"
      ".zig-cache"
      "dist"
      "node_modules"
      "result"
      "target"
    ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "2h";
    };
    pruneOpts = [
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };

  systemd.services.restic-backups-home.unitConfig.RequiresMountsFor = [ "/mnt/shared" ];
}
