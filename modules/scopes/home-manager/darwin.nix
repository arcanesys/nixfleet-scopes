# Home Manager Darwin integration scope.
#
# `useUserPackages` is not applicable on Darwin and is omitted.
# profileImports fans out to the primary operator only (Darwin doesn't
# support multi-user operator fan-out in practice).
{
  inputs,
  lib,
  config,
  ...
}: let
  cfg = config.nixfleet.home-manager;

  # Safe access to operators - works whether or not operators scope is imported.
  primaryName = config.nixfleet.operators._primaryName or null;
in {
  imports = [
    ./options.nix
    inputs.home-manager.darwinModules.home-manager
  ];

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home-manager = {
        useGlobalPkgs = cfg.useGlobalPkgs;
        backupCommand = cfg.backupCommand;
      };
    }

    # Fan out profileImports to primary operator on Darwin.
    (lib.mkIf (cfg.profileImports != [] && primaryName != null) {
      home-manager.users.${primaryName}.imports = cfg.profileImports;
    })
  ]);
}
