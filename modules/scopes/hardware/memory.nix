# Zram compressed swap + earlyoom OOM killer.
{
  config,
  lib,
  ...
}: let
  hw = config.nixfleet.hardware;
in {
  config = lib.mkIf hw.memory.zramSwap {
    zramSwap = {
      enable = true;
      memoryPercent = 25;
      algorithm = "zstd";
    };

    services.earlyoom = {
      enable = true;
      freeMemThreshold = 5;
    };
  };
}
