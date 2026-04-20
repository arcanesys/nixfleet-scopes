# VPN framework - profile-driven, protocol-agnostic.
# Profiles declare type + interface + connection details.
# Drivers implement the protocol-specific config.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.vpn;

  vpnProfileModule = {name, ...}: {
    options = {
      type = lib.mkOption {
        type = lib.types.enum ["wireguard"];
        description = "VPN protocol type. Determines which driver handles this profile.";
      };

      interface = lib.mkOption {
        type = lib.types.str;
        default = "wg-${name}";
        description = "Network interface name for this VPN.";
      };

      listenPort = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        description = "Listen port (null = kernel-assigned).";
      };
    };
  };
in {
  imports = [
    ./drivers/wireguard.nix
  ];

  options.nixfleet.vpn = {
    enable = lib.mkEnableOption "VPN subsystem";

    firewall.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Auto-open listen ports for active VPN profiles.";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule vpnProfileModule);
      default = {};
      description = "VPN profiles. Each profile is handled by its type's driver.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.firewall.enable {
      networking.firewall.allowedUDPPorts =
        lib.filter (p: p != null)
        (lib.mapAttrsToList (_: p: p.listenPort) cfg.profiles);
    })
  ]);
}
