# Rich NixOS generation labels from flake metadata.
# Example boot entry: "20260417-1430_a29a4853_brave-otter"
#
# Requires `inputs.self` passed via specialArgs by the consumer's flake.
{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.nixfleet.generationLabel;

  self = inputs.self or {};

  date = builtins.substring 0 8 (self.lastModifiedDate or "unknown");
  time = builtins.substring 8 4 (self.lastModifiedDate or "");
  rev = builtins.substring 0 8 (self.rev or self.dirtyRev or "dirty");

  adjectives = ["cosmic" "neon" "turbo" "fuzzy" "hyper" "pixel" "cyber" "solar" "ultra" "mega"];
  animals = ["kraken" "phoenix" "panda" "falcon" "otter" "mantis" "lynx" "cobra" "raven" "fox"];
  hash = builtins.hashString "sha256" rev;
  hexMap = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
  };
  hexToInt = s: lib.foldl (acc: c: acc * 16 + hexMap.${c}) 0 (lib.stringToCharacters s);
  idx1 = lib.mod (hexToInt (builtins.substring 0 6 hash)) (builtins.length adjectives);
  idx2 = lib.mod (hexToInt (builtins.substring 6 6 hash)) (builtins.length animals);
  codename = "${builtins.elemAt adjectives idx1}-${builtins.elemAt animals idx2}";

  label =
    if cfg.showCodename
    then "${date}-${time}_${rev}_${codename}"
    else "${date}-${time}_${rev}";
in {
  options.nixfleet.generationLabel = {
    enable = lib.mkEnableOption "rich generation labels in boot menu";

    showCodename = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Append a deterministic codename derived from the git revision hash.";
    };
  };

  config = lib.mkIf cfg.enable {
    system.nixos.label = lib.mkOverride 49 label;
  };
}
