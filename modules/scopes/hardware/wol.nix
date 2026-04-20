# Wake-on-LAN - enable WoL on the primary network interface.
{
  config,
  pkgs,
  lib,
  ...
}: let
  hw = config.nixfleet.hardware;
  iface = config.hostSpec.networking.interface or null;
in {
  config = lib.mkIf (hw.wol.enable && iface != null) {
    environment.systemPackages = [pkgs.ethtool];

    systemd.services.wol = {
      description = "Enable Wake-on-LAN on ${iface}";
      after = ["network.target"];
      wantedBy = ["multi-user.target" "suspend.target"];
      before = ["sleep.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkgs.ethtool} -s ${iface} wol g";
      };
    };
  };
}
