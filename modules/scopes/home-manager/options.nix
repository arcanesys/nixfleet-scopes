# Home Manager scope options - shared between the NixOS and Darwin variants.
# Pure option declarations only; safe to import in any context.
{lib, ...}: {
  options.nixfleet.home-manager = {
    enable = lib.mkEnableOption "Home Manager injection via nixfleet-scopes";

    useGlobalPkgs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Pass the NixOS/Darwin `pkgs` to Home Manager (no second evaluation of nixpkgs).";
    };

    useUserPackages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install user packages via the system activation script (NixOS only; ignored on Darwin).";
    };

    backupCommand = lib.mkOption {
      type = lib.types.str;
      default = ''mv {} {}.nbkp.$(date +%Y%m%d%H%M%S) && ls -t {}.nbkp.* 2>/dev/null | tail -n +6 | xargs -r rm -f'';
      description = "Shell command to back up existing files that would be overwritten by HM activation.";
    };

    profileImports = lib.mkOption {
      type = lib.types.listOf lib.types.unspecified;
      default = [];
      description = ''
        HM modules applied to all operators with homeManager.enable = true.
        Profiles set this; the scope distributes to the right users.
        On NixOS: fans out to all HM-enabled operators.
        On Darwin: applies to the primary operator only.
      '';
    };
  };
}
