# Firewall hardening - nftables backend, SSH rate limiting, drop logging.
# Also forwards bridge traffic for microVM hosts when the microvm-host
# service is enabled downstream.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.firewall;
  hasMicrovm = config.services ? nixfleet-microvm-host;
  microvmEnabled = hasMicrovm && config.services.nixfleet-microvm-host.enable;
  bridgeName =
    if hasMicrovm
    then config.services.nixfleet-microvm-host.bridge.name
    else "";
in {
  options.nixfleet.firewall = {
    enable = lib.mkEnableOption "NixFleet firewall hardening (nftables, SSH rate limiting, drop logging)";
  };

  config = lib.mkIf cfg.enable {
    # Enable nftables backend.
    # Forward-compatible with kernel 6.17+ (which drops ip_tables module).
    # Repos using iptables extraCommands will get an assertion failure -
    # this is intentional, forcing migration before the kernel forces it.
    networking.nftables.enable = true;

    # `lib.escapeShellArg` is wrong for nftables rule text (which is
    # parsed by nft, not the shell); emit the bridge name verbatim
    # and defend against injection with an assertion.
    assertions = lib.optional microvmEnabled {
      assertion = builtins.match "[A-Za-z][A-Za-z0-9_-]*" bridgeName != null;
      message = ''
        services.nixfleet-microvm-host.bridge.name (${bridgeName}) must match
        [A-Za-z][A-Za-z0-9_-]* - the name is interpolated verbatim into
        nftables rules by the firewall scope.
      '';
    };

    networking.firewall = {
      # Log dropped connections for debugging
      logRefusedConnections = true;
      logReversePathDrops = true;

      # SSH rate limiting - 5 new connections per minute per source IP
      extraInputRules = lib.concatStringsSep "\n" (
        [
          "tcp dport 22 ct state new limit rate 5/minute accept"
          "tcp dport 22 ct state new drop"
        ]
        # Allow DHCP on bridge interface when microVM host is enabled
        ++ lib.optionals microvmEnabled [
          "iifname \"${bridgeName}\" udp dport 67 accept"
        ]
      );

      # Allow forwarding through the microVM bridge
      extraForwardRules = lib.mkIf microvmEnabled ''
        iifname "${bridgeName}" accept
        oifname "${bridgeName}" ct state established,related accept
      '';
    };
  };
}
