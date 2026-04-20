# GRUB bootloader for BIOS/legacy boot hosts.
# Overrides the default systemd-boot configuration.
{
  config,
  lib,
  ...
}: let
  hw = config.nixfleet.hardware;
in {
  config = lib.mkIf hw.legacyBoot {
    boot.loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;
      grub = {
        enable = true;
        efiSupport = false;
      };
    };
  };
}
