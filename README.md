# nixfleet-scopes

[![CI](https://github.com/arcanesys/nixfleet-scopes/actions/workflows/ci.yml/badge.svg)](https://github.com/arcanesys/nixfleet-scopes/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE-MIT)
[![v0.1.0](https://img.shields.io/github/v/tag/arcanesys/nixfleet-scopes?label=version)](https://github.com/arcanesys/nixfleet-scopes/releases/tag/v0.1.0)

Reusable infrastructure scopes, roles, and disk templates for [NixFleet](https://github.com/arcanesys/nixfleet). Import a role to get a working NixOS or Darwin baseline, then override individual scopes as needed.

## What this ships

- **17 scopes** (`modules/scopes/`) - NixOS/Darwin modules under `nixfleet.<scope>.*` options:
  - `base` - universal CLI tools (NixOS / Darwin / Home Manager variants)
  - `operators` - declarative multi-user management: primary user, SSH keys, sudo, HM routing
  - `firewall` - nftables hardening with SSH rate limiting and drop logging
  - `secrets` - backend-agnostic identity path management for agenix/sops wiring
  - `backup` - timer scaffolding with restic/borgbackup backends (NixOS + Darwin)
  - `monitoring` - Prometheus node exporter with fleet-tuned collector defaults
  - `monitoring-server` - Prometheus server with alert rules (HostDown, DiskSpaceHigh, SystemdUnitFailed)
  - `impermanence` - btrfs root wipe + system/user persistence paths
  - `home-manager` - opt-in HM injection, fans out profileImports to HM-enabled operators
  - `disko` - disko NixOS module injection (inert without disko.devices)
  - `o11y` - observability: metrics remote-write + systemd-journal-upload
  - `vpn` - VPN framework: profile-driven, wireguard backend
  - `compliance` - filesystem integration for nixfleet-compliance evidence
  - `generation-label` - rich boot entry labels from flake metadata
  - `remote-builders` - cross-platform distributed build delegation
  - `hardware` - auto-imports hardware sub-modules (microcode, bluetooth, nvidia, wol, memory, legacy boot)
  - `terminal-compat` - terminfo for modern terminals + headless essentials
- **4 roles** (`modules/roles/`) - compose scopes with sensible defaults:
  - `server` - headless: base, operators, firewall, secrets, monitoring, impermanence, o11y, generation-label, terminal-compat, hardware
  - `workstation` - interactive: base, operators, firewall, secrets, home-manager, backup, impermanence, o11y, generation-label, terminal-compat, hardware
  - `endpoint` - locked-down: base, operators, secrets, impermanence
  - `microvm-guest` - minimal: base, operators, impermanence
- **2 platform shims** (`modules/platform/`) - minimal common config for NixOS / Darwin
- **6 disk templates** (`modules/disk-templates/`) - disko layouts: btrfs, btrfs-bios, btrfs-impermanence, btrfs-impermanence-bios, ext4, luks-btrfs-impermanence

## What this does NOT ship

Deliberately kept out to stay generic:

- **User profiles** (`developer`, `ops`, `restricted`) - organization-specific; live in consuming fleet repos
- **Desktop environments** - fleet-specific opinions about window managers, display managers, theming
- **Framework services** (`nixfleet-agent`, `nixfleet-control-plane`, `nixfleet-cache`) - services, not infrastructure opinions; stay in [nixfleet](https://github.com/arcanesys/nixfleet)

## Quick start

```nix
{
  inputs.nixfleet.url = "github:arcanesys/nixfleet";

  outputs = { nixfleet, ... }: {
    nixosConfigurations.myhost = nixfleet.lib.mkHost {
      hostName = "myhost";
      platform = "x86_64-linux";
      modules = [
        nixfleet.scopes.roles.workstation
        ./hardware-configuration.nix
        ({ ... }: {
          nixfleet.operators = {
            primaryUser = "alice";
            users.alice = {
              isAdmin = true;
              sshAuthorizedKeys = [ "ssh-ed25519 AAAA..." ];
            };
          };
        })
      ];
    };
  };
}
```

Note: `nixfleet.scopes` re-exports nixfleet-scopes, so you don't need a separate flake input.

## Architecture

Every host composes three orthogonal axes (plus identity via operators):

| Axis | Lives in | Captures | Examples |
|------|----------|----------|----------|
| **Role** | nixfleet-scopes (this repo) | What the host IS (OS posture) | `workstation`, `server`, `endpoint`, `microvm-guest` |
| **Profile** | consuming fleet | Who uses it / how | `developer`, `family`, `operator` |
| **Hardware** | consuming fleet (or `nixos-hardware`) | What hardware it has | `desktop-amd-nvidia`, `apple-silicon` |

Roles are generic and upstream-able. Profiles and hardware bundles encode opinions specific to each adopter.

### Namespace ownership

| Prefix | Owner |
|--------|-------|
| `nixfleet.*` | nixfleet-scopes (this repo) |
| `fleet.*` | consuming fleet |
| `securix.*` | [arcanesys/securix](https://github.com/arcanesys/securix) |

### Override pattern

Roles set scope defaults with `lib.mkDefault` (priority 1000). Override at the host level with `lib.mkForce`:

```nix
modules = [
  nixfleet.scopes.roles.workstation
  ({ lib, ... }: { nixfleet.firewall.enable = lib.mkForce false; })
];
```

## Documentation

Full documentation - scope reference, role details, architecture, and usage patterns - lives in the [NixFleet docs](https://arcanesys.github.io/nixfleet).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT. See [`LICENSE-MIT`](./LICENSE-MIT).
