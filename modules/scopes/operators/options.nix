# Operators scope - option declarations (platform-agnostic).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.operators;

  operatorModule = {name, ...}: {
    options = {
      isAdmin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Add wheel group (sudo access).";
      };

      hashedPassword = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hashed password string for this operator.";
      };

      hashedPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to file containing hashed password.";
      };

      sshAuthorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "SSH public keys for authorized_keys.";
      };

      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional groups on top of roleGroups.";
      };

      homeManager = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Apply the profile's HM stack to this operator.";
        };
      };

      shell = lib.mkOption {
        type = lib.types.package;
        default = pkgs.bash;
        description = "Login shell for this operator.";
      };
    };
  };

  # Resolve the primary operator name.
  primaryName =
    if cfg.primaryUser != null
    then cfg.primaryUser
    else if lib.length (lib.attrNames cfg.users) == 1
    then lib.head (lib.attrNames cfg.users)
    else throw "nixfleet.operators: multiple operators defined, set primaryUser";
in {
  options.nixfleet.operators = {
    primaryUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Name of the primary operator. Auto-detected when only one
        operator is defined. The primary operator is the identity
        anchor for Home Manager, secrets, and impermanence.
      '';
    };

    mutableUsers = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow imperative user/password changes via passwd.";
    };

    roleGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Groups added to ALL operators. Set by roles (workstation adds
        networkmanager/video/audio, server adds nothing). Consumers
        should use per-operator extraGroups for fine-tuning.
      '';
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule operatorModule);
      default = {};
      description = "Declared operators for this host.";
    };

    rootSshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        SSH public keys authorized for root access. Independent of local
        operator accounts - root SSH is an infrastructure concern, not a
        user account concern. Set to _adminSshKeys to give all admins root.
      '';
    };

    # Internal: resolved values for other scopes to read.
    _primaryName = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = primaryName;
      description = "Resolved primary operator name.";
    };

    _primary = lib.mkOption {
      type = lib.types.submodule operatorModule;
      internal = true;
      readOnly = true;
      default = cfg.users.${primaryName};
      description = "Resolved primary operator config.";
    };

    _adminNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      default = lib.attrNames (lib.filterAttrs (_: op: op.isAdmin) cfg.users);
      description = "Operator names with isAdmin=true.";
    };

    _adminSshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      default = lib.concatMap (name: cfg.users.${name}.sshAuthorizedKeys) (lib.attrNames (lib.filterAttrs (_: op: op.isAdmin) cfg.users));
      description = "Aggregated SSH keys from all admin operators.";
    };
  };
}
