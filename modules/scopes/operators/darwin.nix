# Operators scope - Darwin user creation.
#
# nix-darwin has a compatible but simpler users.users API: name, home,
# shell, uid, gid, description. NixOS-specific fields (isNormalUser,
# hashedPassword, openssh, extraGroups) are not available on Darwin.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.operators;
in {
  imports = [./options.nix];

  config = lib.mkIf (cfg.users != {}) {
    users.users =
      lib.mapAttrs (name: op: {
        name = name;
        home = "/Users/${name}";
        shell = op.shell;
      })
      cfg.users;
  };
}
