# Compliance integration - filesystem glue for nixfleet-compliance.
#
# Persists evidence directory on impermanent hosts and sets
# configurationRevision from the flake rev. No hard dependency on
# nixfleet-compliance - just prepares the environment.
#
# Governance configuration (hostType, exceptions, enforceMode) belongs
# in the consuming fleet's compliance module, not here - it requires
# nixfleet-compliance options to be loaded.
{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.nixfleet.compliance;
  impermanenceEnabled = config.nixfleet.impermanence.enable or false;
  self = inputs.self or {};
in {
  options.nixfleet.compliance = {
    enable = lib.mkEnableOption "compliance filesystem integration";

    evidenceDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/nixfleet-compliance";
      description = "Directory where nixfleet-compliance writes evidence.json.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Set configurationRevision so the supply-chain probe can read it.
    {
      system.configurationRevision = lib.mkDefault (self.rev or self.dirtyRev or null);
    }

    # Persist evidence directory on impermanent hosts.
    (lib.mkIf impermanenceEnabled {
      environment.persistence."/persist".directories = [cfg.evidenceDir];
    })
  ]);
}
