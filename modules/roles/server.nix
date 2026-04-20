# Server role - headless host, monitoring on by default, no Home Manager.
#
# Scopes: base + operators + firewall + secrets + monitoring + impermanence
# (impermanence is imported for the `environment.persistence` option -
# activation is opt-in via `nixfleet.impermanence.enable`).
#
# User creation is delegated to the operators scope (hostSpec.userName /
# sshAuthorizedKeys / hashedPasswordFile). Server posture assumes SSH-only
# access - no graphical/audio/docker groups.
{lib, ...}: {
  imports = [
    ../scopes/base
    ../scopes/operators
    ../scopes/firewall
    ../scopes/secrets
    ../scopes/monitoring
    ../scopes/impermanence
    ../scopes/o11y
    ../scopes/generation-label
    ../scopes/terminal-compat
    ../scopes/hardware
  ];

  config = {
    nixfleet.firewall.enable = lib.mkDefault true;
    nixfleet.secrets.enable = lib.mkDefault true;
    nixfleet.secrets.identityPaths.enableUserKey = lib.mkDefault false;
    nixfleet.monitoring.nodeExporter.enable = lib.mkDefault true;

    nixfleet.o11y.metrics.enable = lib.mkDefault true;
    nixfleet.generationLabel.enable = lib.mkDefault true;
    nixfleet.terminalCompat.enable = lib.mkDefault true;

    # Server posture: SSH-only, no graphical/audio/docker groups.
    nixfleet.operators.roleGroups = lib.mkDefault [];
  };
}
