# Operators scope - NixOS user creation.
#
# Roles set `nixfleet.operators.roleGroups` to control what groups all
# operators receive. Consumers declare operators in
# `nixfleet.operators.users.<name>`. One operator is designated
# `primaryUser` - the identity anchor for HM, secrets, impermanence.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.operators;
in {
  imports = [./options.nix];

  config = lib.mkIf (cfg.users != {}) {
    users.mutableUsers = cfg.mutableUsers;

    users.users =
      lib.mapAttrs (name: op: {
        isNormalUser = true;
        shell = lib.mkOverride 900 op.shell;
        hashedPassword = lib.mkIf (op.hashedPassword != null) op.hashedPassword;
        hashedPasswordFile = lib.mkIf (op.hashedPasswordFile != null) op.hashedPasswordFile;
        openssh.authorizedKeys.keys = op.sshAuthorizedKeys;
        extraGroups =
          cfg.roleGroups
          ++ (lib.optional op.isAdmin "wheel")
          ++ op.extraGroups;
      })
      cfg.users;
  };
}
