# Test helpers - stub hostSpec module and operators stub for eval coverage.
{lib}: {
  # Minimal hostSpec identity module.
  # Mirrors the nixfleet hostSpec shape. Used by tests
  # to give scopes a valid `config.hostSpec.*` to read from.
  hostSpecStub = {
    options.hostSpec = {
      userName = lib.mkOption {
        type = lib.types.str;
        default = "testuser";
      };
      hostName = lib.mkOption {
        type = lib.types.str;
        default = "testhost";
      };
      home = lib.mkOption {
        type = lib.types.str;
        default = "/home/testuser";
      };
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = "UTC";
      };
      locale = lib.mkOption {
        type = lib.types.str;
        default = "en_US.UTF-8";
      };
      keyboardLayout = lib.mkOption {
        type = lib.types.str;
        default = "us";
      };
      networking = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
      };
      secretsPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      sshAuthorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      hashedPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      rootHashedPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      isDarwin = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  # Minimal filesystem + bootloader + state so `nixosSystem` evaluates
  # without requiring a real hardware-configuration.nix.
  nixosEvalStub = {
    boot.loader.grub = {
      enable = true;
      devices = ["/dev/vda"];
    };
    fileSystems."/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
    system.stateVersion = "24.11";
  };

  # Minimal operators declaration for eval tests.
  # Provides a single admin operator so the operators scope can resolve
  # _primaryName and create users.users.testuser.
  operatorsStub = {lib, ...}: {
    nixfleet.operators = {
      primaryUser = "testuser";
      users.testuser = {
        isAdmin = true;
        sshAuthorizedKeys = ["ssh-ed25519 AAAA-test-key"];
        homeManager.enable = false;
      };
    };
  };
}
