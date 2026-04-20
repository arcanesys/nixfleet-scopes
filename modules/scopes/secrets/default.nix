# Secrets wiring - backend-agnostic identity path management.
# Provides identity path computation, impermanence persistence,
# boot ordering (host key generation), and key validation.
# Consumers import their chosen backend (agenix, sops-nix) separately and
# read `config.nixfleet.secrets.resolvedIdentityPaths`.
#
# `environment.persistence` contribution is wrapped in an outer
# `lib.mkIf impermanenceEnabled` so the attribute path is only
# constructed when the impermanence scope (or some other consumer of
# `inputs.impermanence.nixosModules.impermanence`) is also imported.
# This avoids the option-declared-twice error that occurs when two
# sibling scopes each forward the impermanence NixOS module.
{
  config,
  lib,
  pkgs,
  ...
}: let
  hS = config.hostSpec;
  cfg = config.nixfleet.secrets;
  types = lib.types;
  impermanenceEnabled = config.nixfleet.impermanence.enable or false;
in {
  options.nixfleet.secrets = {
    enable = lib.mkEnableOption "NixFleet secrets wiring (identity paths, persist, boot ordering)";

    identityPaths = {
      hostKey = lib.mkOption {
        type = types.nullOr types.str;
        default = "/etc/ssh/ssh_host_ed25519_key";
        description = "Primary decryption identity (host SSH key). Used on all hosts.";
      };

      userKey = lib.mkOption {
        type = types.nullOr types.str;
        default = "${hS.home}/.keys/id_ed25519";
        defaultText = lib.literalExpression ''"''${config.hostSpec.home}/.keys/id_ed25519"'';
        description = "Fallback decryption identity (user key). Used on workstations only.";
      };

      enableUserKey = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable user key as fallback. Roles/profiles that run headless should set this to false.";
      };

      extra = lib.mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional identity paths appended to the resolved list.";
      };
    };

    resolvedIdentityPaths = lib.mkOption {
      type = types.listOf types.str;
      readOnly = true;
      internal = true;
      description = ''
        Computed identity paths list. Consumed by fleet secret
        modules (agenix/sops/...) that need the resolved list -
        this is an introspection hook, not an operator option.
      '';
    };
  };

  config = lib.mkMerge [
    # Always compute resolvedIdentityPaths (even when not enabled, for introspection)
    {
      nixfleet.secrets.resolvedIdentityPaths =
        lib.optional (cfg.identityPaths.hostKey != null) cfg.identityPaths.hostKey
        ++ lib.optional (cfg.identityPaths.enableUserKey && cfg.identityPaths.userKey != null) cfg.identityPaths.userKey
        ++ cfg.identityPaths.extra;
    }

    # Active config only when enabled
    (lib.mkIf cfg.enable {
      # Boot ordering: ensure host key exists before sshd
      systemd.services."nixfleet-host-key-check" = lib.mkIf (cfg.identityPaths.hostKey != null) {
        description = "Ensure SSH host key exists for secret decryption";
        wantedBy = ["multi-user.target"];
        before = ["sshd.service"];
        unitConfig.ConditionPathExists = "!${cfg.identityPaths.hostKey}";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "${cfg.identityPaths.hostKey}" -N ""
        '';
      };

      # Key validation: non-fatal warning at activation
      system.activationScripts.nixfleet-secrets-check = lib.stringAfter ["users"] ''
        for key in ${lib.concatStringsSep " " (map lib.escapeShellArg cfg.resolvedIdentityPaths)}; do
          if [[ ! -f "$key" ]]; then
            echo "WARNING: nixfleet.secrets identity key missing: $key (expected on first boot)"
          fi
        done
      '';
    })

    # Impermanence persist paths - OUTER mkIf so `environment.persistence`
    # is only referenced when impermanence is actually enabled. Keeps
    # this scope usable in endpoint hosts that don't import impermanence.
    (lib.mkIf (cfg.enable && impermanenceEnabled) {
      environment.persistence."/persist".files =
        lib.optional (cfg.identityPaths.hostKey != null) cfg.identityPaths.hostKey
        ++ lib.optional (cfg.identityPaths.hostKey != null) "${cfg.identityPaths.hostKey}.pub";
    })
  ];
}
