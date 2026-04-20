# flake-parts module - wires scopes / roles / platform shims / disk
# templates into flake outputs, plus treefmt for formatting and an
# eval-only check for CI.
{
  inputs,
  lib,
  self,
  ...
}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  flake.scopes = {
    roles = {
      server = ./roles/server.nix;
      workstation = ./roles/workstation.nix;
      endpoint = ./roles/endpoint.nix;
      microvm-guest = ./roles/microvm-guest.nix;
    };

    # Generic infrastructure scopes.
    # Each entry is a path (module directory or file); module system
    # picks up `default.nix` when passed a directory.
    base = ./scopes/base;
    baseDarwin = ./scopes/base/darwin.nix;
    baseHm = ./scopes/base/hm.nix;
    operators = ./scopes/operators;
    operatorsDarwin = ./scopes/operators/darwin.nix;
    firewall = ./scopes/firewall;
    secrets = ./scopes/secrets;
    backup = ./scopes/backup;
    monitoring = ./scopes/monitoring;
    impermanence = ./scopes/impermanence;
    impermanenceHm = ./scopes/impermanence/hm.nix;
    home-manager = ./scopes/home-manager;
    home-managerDarwin = ./scopes/home-manager/darwin.nix;
    disko = ./scopes/disko;
    o11y = ./scopes/o11y;
    vpn = ./scopes/vpn;
    compliance = ./scopes/compliance;
    generation-label = ./scopes/generation-label;
    remote-builders = ./scopes/remote-builders;
    hardware = ./scopes/hardware;
    hardware-secure-boot = ./scopes/hardware/secure-boot.nix;
    terminal-compat = ./scopes/terminal-compat;
    monitoring-server = ./scopes/monitoring-server;
    backupDarwin = ./scopes/backup/darwin.nix;

    platform = {
      nixos-base = ./platform/nixos-base.nix;
      darwin-base = ./platform/darwin-base.nix;
    };

    disk-templates = {
      btrfs = ./disk-templates/btrfs-disk.nix;
      btrfs-bios = ./disk-templates/btrfs-disk-bios.nix;
      btrfs-impermanence = ./disk-templates/btrfs-impermanence-disk.nix;
      btrfs-impermanence-bios = ./disk-templates/btrfs-impermanence-disk-bios.nix;
      ext4 = ./disk-templates/ext4-disk.nix;
      luks-btrfs-impermanence = ./disk-templates/luks-btrfs-impermanence-disk.nix;
    };
  };

  # Convenience alias - every scope as a nixosModule for consumers
  # that prefer `inputs.nixfleet-scopes.nixosModules.<name>`.
  flake.nixosModules = {
    base = ./scopes/base;
    operators = ./scopes/operators;
    firewall = ./scopes/firewall;
    secrets = ./scopes/secrets;
    backup = ./scopes/backup;
    monitoring = ./scopes/monitoring;
    impermanence = ./scopes/impermanence;
    home-manager = ./scopes/home-manager;
    disko = ./scopes/disko;
    o11y = ./scopes/o11y;
    vpn = ./scopes/vpn;
    compliance = ./scopes/compliance;
    generation-label = ./scopes/generation-label;
    remote-builders = ./scopes/remote-builders;
    hardware = ./scopes/hardware;
    hardware-secure-boot = ./scopes/hardware/secure-boot.nix;
    terminal-compat = ./scopes/terminal-compat;
    monitoring-server = ./scopes/monitoring-server;
    platform-base = ./platform/nixos-base.nix;

    role-server = ./roles/server.nix;
    role-workstation = ./roles/workstation.nix;
    role-endpoint = ./roles/endpoint.nix;
    role-microvm-guest = ./roles/microvm-guest.nix;
  };

  flake.darwinModules = {
    base = ./scopes/base/darwin.nix;
    operators = ./scopes/operators/darwin.nix;
    home-manager = ./scopes/home-manager/darwin.nix;
    backup = ./scopes/backup/darwin.nix;
    remote-builders = ./scopes/remote-builders;
    platform-base = ./platform/darwin-base.nix;
  };

  flake.homeManagerModules = {
    base = ./scopes/base/hm.nix;
    impermanence = ./scopes/impermanence/hm.nix;
  };

  perSystem = {
    pkgs,
    system,
    ...
  }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.alejandra.enable = true;
    };

    # Eval-only check: imports tests/eval.nix and ensures each role +
    # scope evaluates with a minimal hostSpec.
    checks.eval = import ../tests/eval.nix {
      inherit pkgs lib inputs;
      scopesPath = ../.;
    };
  };
}
