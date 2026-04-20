# Backup scaffolding - backend-agnostic timer, hooks, health, persistence.
# Optional concrete backends: restic, borgbackup.
# When backend is null, consumers set
# `systemd.services.nixfleet-backup.serviceConfig.ExecStart` themselves.
#
# `environment.persistence` contribution is wrapped in an outer
# `lib.mkIf impermanenceEnabled` so the attribute path is only
# constructed when the impermanence scope (or some other consumer of
# `inputs.impermanence.nixosModules.impermanence`) is also imported.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.backup;
  impermanenceEnabled = config.nixfleet.impermanence.enable or false;

  excludeFlags =
    lib.concatMapStringsSep " " (p: "--exclude ${lib.escapeShellArg p}") cfg.exclude;

  resticBackupScript = pkgs.writeShellScript "nixfleet-backup-restic" ''
    set -euo pipefail
    export RESTIC_REPOSITORY=${lib.escapeShellArg cfg.restic.repository}
    export RESTIC_PASSWORD_FILE=${lib.escapeShellArg cfg.restic.passwordFile}
    export RESTIC_CACHE_DIR=${cfg.stateDirectory}/restic-cache

    # Initialize repo if needed (idempotent)
    ${pkgs.restic}/bin/restic cat config >/dev/null 2>&1 || \
      ${pkgs.restic}/bin/restic init

    # Backup
    ${pkgs.restic}/bin/restic backup \
      --tag ${lib.escapeShellArg config.hostSpec.hostName} \
      ${excludeFlags} \
      ${lib.concatStringsSep " " (map lib.escapeShellArg cfg.paths)}

    # Prune
    ${pkgs.restic}/bin/restic forget \
      --keep-daily ${toString cfg.retention.daily} \
      --keep-weekly ${toString cfg.retention.weekly} \
      --keep-monthly ${toString cfg.retention.monthly} \
      --prune
  '';

  borgArchiveName = "${config.hostSpec.hostName}-{now:%Y-%m-%dT%H:%M:%S}";

  borgBackupScript = pkgs.writeShellScript "nixfleet-backup-borg" ''
    set -euo pipefail
    export BORG_REPO=${lib.escapeShellArg cfg.borgbackup.repository}
    ${lib.optionalString (cfg.borgbackup.passphraseFile != null)
      "export BORG_PASSCOMMAND=\"cat ${lib.escapeShellArg cfg.borgbackup.passphraseFile}\""}
    ${lib.optionalString (cfg.borgbackup.passphraseFile == null)
      "export BORG_PASSPHRASE=\"\""}

    # Initialize repo if needed (idempotent)
    ${pkgs.borgbackup}/bin/borg info "$BORG_REPO" >/dev/null 2>&1 || \
      ${pkgs.borgbackup}/bin/borg init --encryption=${lib.escapeShellArg cfg.borgbackup.encryption}

    # Backup
    ${pkgs.borgbackup}/bin/borg create \
      ${excludeFlags} \
      "$BORG_REPO::${borgArchiveName}" \
      ${lib.concatStringsSep " " (map lib.escapeShellArg cfg.paths)}

    # Prune
    ${pkgs.borgbackup}/bin/borg prune \
      --keep-daily ${toString cfg.retention.daily} \
      --keep-weekly ${toString cfg.retention.weekly} \
      --keep-monthly ${toString cfg.retention.monthly}

    ${pkgs.borgbackup}/bin/borg compact
  '';
in {
  imports = [./options.nix];

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Fail early at eval time if the selected backend's required
      # fields are left at their empty defaults. A runtime failure
      # from restic/borg would be harder to diagnose.
      assertions = [
        {
          assertion = cfg.backend != "restic" || (cfg.restic.repository != "" && cfg.restic.passwordFile != "");
          message = "nixfleet.backup: restic backend requires restic.repository and restic.passwordFile";
        }
        {
          assertion = cfg.backend != "borgbackup" || cfg.borgbackup.repository != "";
          message = "nixfleet.backup: borgbackup backend requires borgbackup.repository";
        }
      ];

      # Systemd timer with staggered delay across fleet
      systemd.timers.nixfleet-backup = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = cfg.schedule;
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };

      # Service skeleton - backend sets ExecStart, or consumer overrides
      systemd.services.nixfleet-backup = {
        description = "NixFleet Backup";
        after = ["network-online.target"];
        wants = ["network-online.target"];

        serviceConfig = lib.mkMerge [
          {
            Type = "oneshot";
            StateDirectory = "nixfleet-backup";
          }
          (lib.mkIf (cfg.backend == "restic") {
            ExecStart = resticBackupScript;
          })
          (lib.mkIf (cfg.backend == "borgbackup") {
            ExecStart = borgBackupScript;
          })
        ];

        # Pre-hook
        preStart = lib.mkIf (cfg.preHook != "") cfg.preHook;

        # Post-hook + health ping + status reporting
        postStart = let
          postHookCmd = lib.optionalString (cfg.postHook != "") cfg.postHook;
          healthCmd =
            lib.optionalString (cfg.healthCheck.onSuccess != null)
            "${pkgs.curl}/bin/curl -fsS -m 10 --retry 3 ${lib.escapeShellArg cfg.healthCheck.onSuccess} || true";
          statusCmd = ''
            cat > ${cfg.stateDirectory}/status.json <<STATUSEOF
            {"lastRun": "$(date -Is)", "status": "success", "hostname": "${config.hostSpec.hostName}"}
            STATUSEOF
          '';
        in
          lib.concatStringsSep "\n" (lib.filter (s: s != "") [postHookCmd healthCmd statusCmd]);
      };

      # On-failure notification service
      systemd.services.nixfleet-backup-failure = lib.mkIf (cfg.healthCheck.onFailure != null) {
        description = "NixFleet Backup Failure Notification";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.curl}/bin/curl -fsS -m 10 --retry 3 ${lib.escapeShellArg cfg.healthCheck.onFailure}";
        };
      };
      systemd.services.nixfleet-backup.unitConfig.OnFailure =
        lib.mkIf (cfg.healthCheck.onFailure != null) ["nixfleet-backup-failure.service"];

      # Add backend packages to system
      environment.systemPackages =
        lib.optional (cfg.backend == "restic") pkgs.restic
        ++ lib.optional (cfg.backend == "borgbackup") pkgs.borgbackup;
    })

    # Impermanence persist paths - OUTER mkIf so `environment.persistence`
    # is only referenced when impermanence is actually enabled. Keeps
    # this scope usable in hosts that don't import the impermanence scope.
    (lib.mkIf (cfg.enable && impermanenceEnabled) {
      environment.persistence."/persist".directories = [cfg.stateDirectory];
    })
  ];
}
