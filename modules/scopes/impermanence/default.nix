# Core impermanence - system-level persist paths + btrfs root wipe.
#
# Unconditionally imports the `impermanence` NixOS module (it's inert
# without `environment.persistence` configured). This means other scopes
# (secrets, backup) can safely contribute `environment.persistence.*`
# paths without each having to import the impermanence NixOS module.
#
# Scope-specific persist paths live in their respective scope modules
# (e.g. `nixfleet.secrets` persists SSH host keys, `nixfleet.backup`
# persists backup state).
{
  inputs,
  config,
  lib,
  ...
}: let
  hS = config.hostSpec;
  cfg = config.nixfleet.impermanence;
in {
  imports = [inputs.impermanence.nixosModules.impermanence];

  options.nixfleet.impermanence = {
    enable = lib.mkEnableOption "NixFleet system-level impermanence (persist + btrfs root wipe)";

    persistRoot = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Mount point for the persistent btrfs subvolume.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.persistence.${cfg.persistRoot} = {
      directories = [
        "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        "/var/lib/systemd"
        "/var/lib/nixos"
        "/var/log"
      ];
      files = ["/etc/machine-id"];
    };

    # --- Ensure persist home has correct ownership ---
    system.activationScripts.persistHomeOwnership = {
      text = ''
        install -d -o ${lib.escapeShellArg hS.userName} -g users ${lib.escapeShellArg "${cfg.persistRoot}/home/${hS.userName}"}
        if [ -d ${lib.escapeShellArg "${cfg.persistRoot}/home/${hS.userName}/.keys"} ]; then
          chown -R ${lib.escapeShellArg hS.userName}:users ${lib.escapeShellArg "${cfg.persistRoot}/home/${hS.userName}/.keys"}
        fi
      '';
      deps = [];
    };

    # --- Btrfs root wipe ---
    boot.initrd.postResumeCommands = lib.mkAfter ''
      mkdir /btrfs_tmp
      mount /dev/disk/by-label/root /btrfs_tmp
      if [[ -e /btrfs_tmp/@root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/@root "/btrfs_tmp/old_roots/$timestamp"
      fi
      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
      }
      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$i"
      done
      btrfs subvolume create /btrfs_tmp/@root
      umount /btrfs_tmp
    '';
    fileSystems.${cfg.persistRoot}.neededForBoot = true;
  };
}
