# Base Home-Manager packages - truly universal CLI tools for every user.
# Activated unconditionally; consumers who want a minimal profile can
# override `home.packages` with `lib.mkForce` or filter this import out.
{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    # Core CLI tools
    coreutils
    killall
    openssh
    wget
    age
    gnupg
    fastfetch
    gh

    # File and disk tools
    duf
    eza
    fd
    fzf
    jq
    procs
    ripgrep
    tldr
    tree
    yq

    # Nix system management
    home-manager
    nh
  ];
}
