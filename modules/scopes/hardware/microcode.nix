# Auto-select CPU microcode and default boot loader from hardware flags.
{
  config,
  lib,
  ...
}: let
  hw = config.nixfleet.hardware;
in {
  config = lib.mkMerge [
    # Microcode
    (lib.mkIf (hw.cpu.vendor == "amd") {
      hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
    })
    (lib.mkIf (hw.cpu.vendor == "intel") {
      hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
    })

    # Default boot loader: systemd-boot when neither legacy nor secure boot
    (lib.mkIf (!hw.legacyBoot && !hw.secureBoot) {
      boot.loader.systemd-boot.enable = lib.mkDefault true;
      boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
    })

    # Mutual exclusion assertion
    {
      assertions = [
        {
          assertion = !(hw.legacyBoot && hw.secureBoot);
          message = "nixfleet.hardware: legacyBoot and secureBoot are mutually exclusive";
        }
      ];
    }
  ];
}
