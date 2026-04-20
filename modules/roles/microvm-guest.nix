# MicroVM guest role - minimal guest on a microVM host.
#
# Scopes: base only.
# The microVM HOST owns:
# - firewall / nftables
# - filesystems
# - backup policy
{lib, ...}: {
  imports = [
    ../scopes/base
    ../scopes/operators
    # Loaded for option-declaration hygiene; activation is opt-in.
    ../scopes/impermanence
  ];

  # microvm-guest role deliberately imports no firewall / HM scopes:
  # the HOST owns those policies. If a consumer later adds the firewall
  # or home-manager scope to a microvm-guest host, they should set the
  # respective `nixfleet.<scope>.enable` explicitly.
  config = {};
}
