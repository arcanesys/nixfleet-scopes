# Hardware capability flags. Set by hardware bundles, read by scopes.
{lib, ...}: {
  options.nixfleet.hardware = {
    nvidia.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "NVIDIA proprietary drivers + modesetting + EGL/OpenGL.";
    };

    bluetooth.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Bluetooth stack (BlueZ + agent).";
    };

    wol.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wake-on-LAN on primary network interface.";
    };

    secureBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Secure Boot (consumer wires lanzaboote).";
    };

    legacyBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "BIOS/legacy boot (GRUB) instead of UEFI.";
    };

    cpu.vendor = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["amd" "intel"]);
      default = null;
      description = "CPU vendor for microcode updates.";
    };

    memory = {
      zramSwap = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable zram compressed swap + earlyoom OOM killer.";
      };
    };
  };
}
