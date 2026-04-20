# Cross-platform distributed build delegation.
# Handles Determinate Nix on Darwin (writes /etc/nix/machines directly).
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.distributedBuilds;
  isDarwin = config.hostSpec.isDarwin or false;

  machineModule = {name, ...}: {
    options = {
      hostName = lib.mkOption {
        type = lib.types.str;
        description = "Hostname or IP of the remote builder.";
      };

      systems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Systems this builder supports (e.g., [\"x86_64-linux\"]).";
      };

      sshUser = lib.mkOption {
        type = lib.types.str;
        default = "nix-build";
        description = "SSH user for build delegation.";
      };

      sshKeyFile = lib.mkOption {
        type = lib.types.str;
        description = "Path to SSH private key for build delegation.";
      };

      maxJobs = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Maximum parallel jobs on this builder.";
      };

      speedFactor = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Relative speed factor (higher = preferred).";
      };

      publicHostKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SSH public host key for known_hosts. Null = no entry.";
      };
    };
  };
in {
  options.nixfleet.distributedBuilds = {
    enable = lib.mkEnableOption "distributed build delegation";

    machines = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule machineModule);
      default = [];
      description = "Remote builders to delegate builds to.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.machines != []) (lib.mkMerge [
    {
      nix.distributedBuilds = true;

      nix.buildMachines =
        map (m: {
          inherit (m) hostName systems sshUser maxJobs speedFactor;
          sshKey = m.sshKeyFile;
        })
        cfg.machines;

      programs.ssh.knownHosts =
        lib.listToAttrs
        (lib.filter (x: x.value.publicKey != null)
          (map (m:
            lib.nameValuePair m.hostName {
              hostNames = [m.hostName];
              publicKey = m.publicHostKey;
            })
          cfg.machines));
    }

    (lib.mkIf isDarwin {
      # Write /etc/nix/machines as a real file (agenix paths only exist
      # at runtime) and append builders config to nix.custom.conf.
      # The core _darwin.nix writes the base nix.custom.conf (trusted-users,
      # substituters) with cat > via mkBefore. We append with cat >> via
      # mkAfter. environment.etc can't be used for /etc/nix/ - Determinate
      # Nix owns that directory and nix-darwin refuses to overwrite real files.
      system.activationScripts.postActivation.text = lib.mkAfter (let
        machineLines =
          lib.concatMapStringsSep "\n" (
            m: "ssh://${m.sshUser}@${m.hostName} ${lib.concatStringsSep "," m.systems} ${m.sshKeyFile} ${toString m.maxJobs} ${toString m.speedFactor} - -"
          )
          cfg.machines;
      in ''
        cat > /etc/nix/machines <<'MACHINES'
        ${machineLines}
        MACHINES
        cat >> /etc/nix/nix.custom.conf <<'NIX_BUILDERS'
        builders = @/etc/nix/machines
        builders-use-substitutes = true
        NIX_BUILDERS
      '');
    })
  ]);
}
