# nixfleet-scopes — archived

This repository is archived. The reusable contract implementations were
absorbed into [arcanesys/nixfleet](https://github.com/arcanesys/nixfleet),
exposed at `flake.scopes.<family>.<impl>`. The remaining modules were
not generalized further and are no longer maintained as a shared
library.

## What moved upstream

- `flake.scopes.persistence.impermanence` — btrfs root-wipe + impermanence wiring
- `flake.scopes.keyslots.tpm` — TPM-backed signing keyslot
- `flake.scopes.gitops.forgejo` / `.gitea` — channel-refs URL builder
- `flake.scopes.secrets` — backend-agnostic identity-path manager

Consumer pattern:

```nix
nixfleet.lib.mkHost {
  modules = [
    nixfleet.scopes.persistence.impermanence
    nixfleet.scopes.secrets
    nixfleet.scopes.keyslots.tpm
  ];
}
```

## History

Last release tagged [`v0.1.0`](https://github.com/arcanesys/nixfleet-scopes/releases/tag/v0.1.0).

## License

MIT. See [`LICENSE-MIT`](./LICENSE-MIT).
