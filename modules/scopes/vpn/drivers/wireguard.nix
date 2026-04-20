# Wireguard protocol driver. Handles profiles with type = "wireguard".
# Uses networking.wireguard.interfaces for clean NixOS integration.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.vpn;

  wgProfiles = lib.filterAttrs (_: p: p.type == "wireguard") cfg.profiles;

  wgProfileModule = {name, ...}: {
    options = {
      privateKeyFile = lib.mkOption {
        type = lib.types.str;
        description = "Path to wireguard private key file (compatible with agenix/sops).";
      };

      peers = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            publicKey = lib.mkOption {type = lib.types.str;};
            endpoint = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            allowedIPs = lib.mkOption {type = lib.types.listOf lib.types.str;};
            persistentKeepalive = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
            };
          };
        });
        default = [];
        description = "Wireguard peers for this profile.";
      };

      address = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "IP addresses to assign to this interface (e.g., [\"10.0.0.1/24\"]).";
      };
    };
  };

  wgOptions = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule wgProfileModule);
  };
in {
  options.nixfleet.vpn.profiles = wgOptions;

  config = lib.mkIf (cfg.enable && wgProfiles != {}) {
    networking.wireguard.interfaces =
      lib.mapAttrs (name: profile: {
        ips = profile.address;
        listenPort = profile.listenPort;
        privateKeyFile = profile.privateKeyFile;
        peers =
          map (peer: {
            inherit (peer) publicKey allowedIPs;
            endpoint = peer.endpoint;
            persistentKeepalive = peer.persistentKeepalive;
          })
          profile.peers;
      })
      (lib.mapAttrs' (name: profile:
        lib.nameValuePair profile.interface profile)
      wgProfiles);
  };
}
