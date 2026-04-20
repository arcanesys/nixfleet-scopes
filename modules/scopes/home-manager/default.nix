# Home Manager NixOS integration scope.
#
# Unconditionally imports the Home Manager NixOS module (it's inert without
# users configured). When `nixfleet.home-manager.enable` is true, sets
# the `useGlobalPkgs` / `useUserPackages` / `backupCommand` defaults and
# fans out `profileImports` to all operators with homeManager.enable = true.
{
  inputs,
  lib,
  config,
  ...
}: let
  cfg = config.nixfleet.home-manager;

  # Safe access to operators - works whether or not operators scope is imported.
  operators = config.nixfleet.operators.users or {};
  hmEnabledOperators = lib.filterAttrs (_: op: op.homeManager.enable or false) operators;
in {
  imports = [
    ./options.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home-manager = {
        useGlobalPkgs = cfg.useGlobalPkgs;
        useUserPackages = cfg.useUserPackages;
        backupCommand = cfg.backupCommand;
      };
    }

    # Fan out profileImports to all HM-enabled operators.
    (lib.mkIf (cfg.profileImports != [] && hmEnabledOperators != {}) {
      home-manager.users =
        lib.mapAttrs (_: _op: {
          imports = cfg.profileImports;
        })
        hmEnabledOperators;
    })
  ]);
}
