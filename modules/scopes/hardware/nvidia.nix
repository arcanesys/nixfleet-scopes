# NVIDIA proprietary drivers - modesetting, initrd modules, Wayland session vars.
{
  config,
  lib,
  ...
}: let
  hw = config.nixfleet.hardware;
in {
  config = lib.mkIf hw.nvidia.enable {
    hardware.nvidia = {
      modesetting.enable = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      powerManagement.enable = true;
    };

    boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_drm"];
    boot.kernelParams = ["nvidia-drm.fbdev=1"];

    hardware.graphics.enable = true;

    environment.sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
    };

    services.xserver.videoDrivers = ["nvidia"];
  };
}
