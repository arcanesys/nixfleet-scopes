# Disko NixOS module injection scope.
#
# Unconditionally imports the disko NixOS module - disko is inert without
# `disko.devices` set. The `nixfleet.disko.enable` option is retained as
# an opt-out hook so consumers can gate future logic that the scope
# might add (health checks, validation) without shadowing upstream disko.
{
  inputs,
  lib,
  config,
  ...
}: let
  cfg = config.nixfleet.disko;
in {
  imports = [inputs.disko.nixosModules.disko];

  options.nixfleet.disko = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the NixFleet disko integration scope (currently just ensures the disko NixOS module is imported).";
    };
  };

  # No config block today - the presence of the import is the activation.
  config = lib.mkIf cfg.enable {};
}
