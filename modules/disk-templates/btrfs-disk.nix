# btrfs disk template - GPT + ESP + btrfs root with @root, @nix, optional @swap.
# Use via `disko.devices` by importing with custom args:
#   disko.devices = import nixfleet-scopes.scopes.disk-templates.btrfs { inherit lib; disk = "/dev/nvme0n1"; };
#
# NOTE: ... is needed because disko passes diskoFile
{
  lib,
  disk ? "/dev/vda",
  espSize ? "512M",
  withSwap ? false,
  swapSize ? "8",
  ...
}: {
  disko.devices = {
    disk = {
      disk0 = {
        type = "disk";
        device = disk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = espSize;
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-L" "root" "-f"];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
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
  };
}
