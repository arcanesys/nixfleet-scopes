# Endpoint role - locked-down, distro-driven host (e.g. Sécurix laptops).
#
# Scopes: base + secrets only.
# Consumer (e.g. securix.nixosModules.securix-base) provides:
# - firewall policy (strict endpoint-specific ruleset)
# - user management (multi-operator, PAM, authorized-users)
# - filesystems (lanzaboote, disko, LUKS)
# - hardware profile (e.g. securix.nixosModules.securix-hardware.<sku>)
{lib, ...}: {
  imports = [
    ../scopes/base
    ../scopes/operators
    ../scopes/secrets
    # impermanence is imported for the `environment.persistence` option
    # declaration (secrets contributes to it when impermanence.enable).
    # Activation stays opt-in via `nixfleet.impermanence.enable`.
    ../scopes/impermanence
  ];

  config = {
    nixfleet.secrets.enable = lib.mkDefault true;
    nixfleet.secrets.identityPaths.enableUserKey = lib.mkDefault true;
  };
}
