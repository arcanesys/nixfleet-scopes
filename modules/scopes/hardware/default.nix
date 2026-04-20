# Hardware scope - auto-imports all sub-modules except secure-boot.
# Secure boot requires lanzaboote (external input); import it separately:
#   inputs.nixfleet-scopes.scopes.hardware-secure-boot
{...}: {
  imports = [
    ./options.nix
    ./microcode.nix
    ./bluetooth.nix
    ./nvidia.nix
    ./wol.nix
    ./memory.nix
    ./legacy-boot.nix
  ];
}
