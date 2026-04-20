# Base NixOS packages - truly universal tools for every NixOS host.
# Dev / graphical / media packages belong in their own fleet-side scopes.
# Tool configs are managed by Home Manager (via the HM variant at ./hm.nix).
{
  pkgs,
  lib,
  config,
  ...
}: {
  options.nixfleet.base = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install universal CLI tools on this host.";
    };
  };

  config = lib.mkIf config.nixfleet.base.enable {
    environment.systemPackages = with pkgs; [
      unixtools.ifconfig
      unixtools.netstat
      xdg-utils
    ];
  };
}
