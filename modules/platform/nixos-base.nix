# NixOS platform shim - minimal common config readable from hostSpec
# identity. Optional: mkHost already handles most of this. This shim
# exists so roles/hosts that bypass mkHost can still pick up sensible
# defaults with a single import.
{
  config,
  lib,
  ...
}: let
  hS = config.hostSpec;
in {
  config = {
    time.timeZone = lib.mkDefault hS.timeZone;
    i18n.defaultLocale = lib.mkDefault hS.locale;
    console.keyMap = lib.mkDefault hS.keyboardLayout;

    nix.settings.experimental-features = lib.mkDefault ["nix-command" "flakes"];
  };
}
