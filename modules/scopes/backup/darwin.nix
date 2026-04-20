# Backup scope - Darwin (launchd) implementation.
# Uses the same nixfleet.backup.* options as the NixOS variant.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.backup;

  resticBin = "${pkgs.restic}/bin/restic";
  curlBin = "${pkgs.curl}/bin/curl";

  pathArgs = lib.concatMapStringsSep " " (p: lib.escapeShellArg p) cfg.paths;
  excludeFlags =
    lib.concatMapStringsSep " " (p: "--exclude ${lib.escapeShellArg p}") cfg.exclude;

  retentionFlags = lib.concatStringsSep " " [
    "--keep-daily ${toString cfg.retention.daily}"
    "--keep-weekly ${toString cfg.retention.weekly}"
    "--keep-monthly ${toString cfg.retention.monthly}"
  ];

  preHookCmd =
    if cfg.preHook != ""
    then cfg.preHook
    else "";
  postHookCmd =
    if cfg.postHook != ""
    then cfg.postHook
    else "";
  successPing =
    if cfg.healthCheck.onSuccess != null
    then "${curlBin} -fsS -o /dev/null ${lib.escapeShellArg cfg.healthCheck.onSuccess}"
    else "";
  failurePing =
    if cfg.healthCheck.onFailure != null
    then "${curlBin} -fsS -o /dev/null ${lib.escapeShellArg cfg.healthCheck.onFailure}"
    else "";

  backupScript = pkgs.writeShellScript "nixfleet-backup-darwin" ''
    set -euo pipefail
    export RESTIC_REPOSITORY=${lib.escapeShellArg cfg.restic.repository}
    export RESTIC_PASSWORD_FILE=${lib.escapeShellArg cfg.restic.passwordFile}

    ${preHookCmd}

    # Initialize repo if needed (idempotent)
    ${resticBin} snapshots &>/dev/null || ${resticBin} init

    # Run backup
    if ${resticBin} backup ${excludeFlags} ${pathArgs}; then
      ${resticBin} forget ${retentionFlags} --prune
      ${postHookCmd}
      ${successPing}
    else
      ${failurePing}
      exit 1
    fi
  '';
in {
  imports = [./options.nix];

  config = lib.mkIf (cfg.enable && cfg.backend == "restic") {
    launchd.daemons.nixfleet-backup = {
      serviceConfig = {
        Label = "org.nixfleet.backup";
        ProgramArguments = ["/bin/sh" "-c" "${backupScript}"];
        StartCalendarInterval = [
          {
            Hour = 2;
            Minute = 0;
          }
        ];
        StandardOutPath = "/tmp/nixfleet-backup.log";
        StandardErrorPath = "/tmp/nixfleet-backup.err";
      };
    };
  };
}
