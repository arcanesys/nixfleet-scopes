# Workstation role - interactive host with a primary user.
#
# Scopes: base + operators + firewall + secrets + home-manager + backup + impermanence
# (impermanence is imported for the `environment.persistence` option -
# activation is opt-in via `nixfleet.impermanence.enable`).
#
# User creation is delegated to the operators scope (hostSpec.userName /
# sshAuthorizedKeys / hashedPasswordFile). Consumers still need to provide:
# - a hardware bundle (GPU/CPU-specific bits)
# - a profile (developer / family / kids / operator - user-facing config)
# - per-user HM imports (via profiles / hardware bundles)
{lib, ...}: {
  imports = [
    ../scopes/base
    ../scopes/operators
    ../scopes/firewall
    ../scopes/secrets
    ../scopes/home-manager
    ../scopes/backup
    ../scopes/impermanence
    ../scopes/o11y
    ../scopes/generation-label
    ../scopes/terminal-compat
    ../scopes/hardware
  ];

  config = {
    nixfleet.firewall.enable = lib.mkDefault true;
    nixfleet.secrets.enable = lib.mkDefault true;
    nixfleet.secrets.identityPaths.enableUserKey = lib.mkDefault true;
    nixfleet.home-manager.enable = lib.mkDefault true;
    nixfleet.backup.enable = lib.mkDefault false;
    nixfleet.o11y.metrics.enable = lib.mkDefault true;
    nixfleet.generationLabel.enable = lib.mkDefault true;
    nixfleet.terminalCompat.enable = lib.mkDefault true;
    nixfleet.hardware.memory.zramSwap = lib.mkDefault true;

    # Workstation posture: interactive login with audio/video/network/docker
    # access if those groups exist on the host.
    nixfleet.operators.roleGroups = lib.mkDefault [
      "networkmanager"
      "video"
      "audio"
      "docker"
    ];
  };
}
