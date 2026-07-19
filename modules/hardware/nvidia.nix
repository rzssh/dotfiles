{ config, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
    nvidiaPersistenced = true;
  };

  boot.kernelParams = [ "nvidia_drm.modeset=1" ];

  systemd.services.nvidia-clock-floor = {
    description = "Lock NVIDIA minimum clocks for desktop smoothness";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${config.hardware.nvidia.package.bin}/bin/nvidia-smi --lock-gpu-clocks=1200,3105"
        "${config.hardware.nvidia.package.bin}/bin/nvidia-smi --lock-memory-clocks=5001,10501"
      ];
      RemainAfterExit = true;
    };
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
