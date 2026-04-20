# Base Darwin packages - truly universal tools for every macOS host.
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
      description = "Install universal Darwin CLI tools on this host.";
    };
  };

  config = lib.mkIf config.nixfleet.base.enable {
    environment.systemPackages = with pkgs; [dockutil mas];
  };
}
