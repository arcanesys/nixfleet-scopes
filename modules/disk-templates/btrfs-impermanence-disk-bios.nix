# btrfs impermanence disk template (BIOS/legacy boot) - GPT + BIOS boot
# partition + btrfs root with @root, @persist, @nix, optional @swap.
# For hosts with nixfleet.hardware.legacyBoot = true.
{
  lib,
  disk ? "/dev/vda",
  withSwap ? false,
  swapSize ? "8",
  ...
}: {
  disk = {
    disk0 = {
      type = "disk";
      device = disk;
      content = {
        type = "gpt";
        partitions = {
          boot = {
            priority = 1;
            name = "BIOS";
            start = "1M";
            end = "2M";
            type = "EF02";
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = ["-L" "root" "-f"];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@swap" = lib.mkIf withSwap {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "${swapSize}G";
                };
              };
            };
          };
        };
      };
    };
  };
}
