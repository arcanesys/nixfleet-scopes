# Secure Boot via lanzaboote - signed kernel + initrd.
#
# Requires the consumer to import lanzaboote:
#   inputs.lanzaboote.nixosModules.lanzaboote
# The scope does not pull lanzaboote as a dependency.
{
  config,
  pkgs,
  lib,
  ...
}: let
  hw = config.nixfleet.hardware;
  impermanenceEnabled = config.nixfleet.impermanence.enable or false;
in {
  config = lib.mkIf hw.secureBoot {
    environment.systemPackages = [pkgs.sbctl];

    # Lanzaboote replaces systemd-boot
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    # Persist secure boot keys on impermanent hosts
    environment.persistence."/persist".directories = lib.mkIf impermanenceEnabled [
      {
        directory = "/etc/secureboot";
        mode = "0700";
      }
    ];
  };
}
