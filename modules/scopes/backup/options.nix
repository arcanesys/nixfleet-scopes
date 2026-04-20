# Backup scope - option declarations (platform-agnostic).
{lib, ...}: let
  types = lib.types;
in {
  options.nixfleet.backup = {
    enable = lib.mkEnableOption "NixFleet backup scaffolding (timer, health, persistence)";

    backend = lib.mkOption {
      type = types.nullOr (types.enum ["restic" "borgbackup"]);
      default = null;
      description = "Backup backend. Null = consumer sets ExecStart manually.";
    };

    paths = lib.mkOption {
      type = types.listOf types.str;
      default = ["/persist"];
      description = "Directories to back up.";
    };

    exclude = lib.mkOption {
      type = types.listOf types.str;
      default = ["/persist/nix" "*.cache" "/tmp" "/run" "/dev/shm"];
      description = "Patterns to exclude from backup. Includes tmpfs mounts by default.";
    };

    schedule = lib.mkOption {
      type = types.str;
      default = "daily";
      description = "Systemd calendar expression (daily, weekly, *-*-* 02:00:00).";
    };

    retention = lib.mkOption {
      type = types.submodule {
        options = {
          daily = lib.mkOption {
            type = types.int;
            default = 7;
            description = "Number of daily snapshots to keep.";
          };
          weekly = lib.mkOption {
            type = types.int;
            default = 4;
            description = "Number of weekly snapshots to keep.";
          };
          monthly = lib.mkOption {
            type = types.int;
            default = 6;
            description = "Number of monthly snapshots to keep.";
          };
        };
      };
      default = {};
      description = "Retention policy. Interpretation depends on chosen backend.";
    };

    healthCheck = {
      onSuccess = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://hc-ping.com/xxx";
        description = "URL to GET on successful backup.";
      };
      onFailure = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "URL to GET on backup failure.";
      };
    };

    preHook = lib.mkOption {
      type = types.lines;
      default = "";
      description = "Shell commands to run before backup.";
    };

    postHook = lib.mkOption {
      type = types.lines;
      default = "";
      description = "Shell commands to run after successful backup.";
    };

    stateDirectory = lib.mkOption {
      type = types.str;
      default = "/var/lib/nixfleet-backup";
      description = "Directory for backup state/cache. Persisted on impermanent hosts.";
    };

    restic = {
      repository = lib.mkOption {
        type = types.str;
        default = "";
        example = "/mnt/backup/restic";
        description = "Restic repository URL or path.";
      };
      passwordFile = lib.mkOption {
        type = types.str;
        default = "";
        example = "/run/secrets/restic-password";
        description = "Path to file containing the repository password.";
      };
    };

    borgbackup = {
      repository = lib.mkOption {
        type = types.str;
        default = "";
        example = "/mnt/backup/borg";
        description = "Borg repository path or ssh://user@host/path.";
      };
      passphraseFile = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to file containing the repository passphrase. Null = repokey without passphrase.";
      };
      encryption = lib.mkOption {
        type = types.str;
        default = "repokey";
        description = "Borg encryption mode (repokey, repokey-blake2, none, etc.).";
      };
    };
  };
}
