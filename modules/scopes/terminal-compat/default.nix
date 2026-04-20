# Terminal compatibility - terminfo for modern terminals + headless essentials.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.terminalCompat;
in {
  options.nixfleet.terminalCompat = {
    enable = lib.mkEnableOption "terminal compatibility (terminfo + headless tools)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kitty.terminfo
      alacritty.terminfo
      wget
      unzip
      curl
    ];
  };
}
