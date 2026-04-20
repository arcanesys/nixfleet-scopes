# Bluetooth stack - BlueZ, rfkill unblock, pairing persistence, consumer control fix.
{
  config,
  pkgs,
  lib,
  ...
}: let
  hw = config.nixfleet.hardware;
  impermanenceEnabled = config.nixfleet.impermanence.enable or false;
in {
  config = lib.mkIf hw.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Persist bluetooth pairings across reboots
    environment.persistence."/persist" = lib.mkIf impermanenceEnabled {
      directories = ["/var/lib/bluetooth"];
    };

    # Unblock bluetooth on boot (some controllers start soft-blocked)
    systemd.services.bluetooth-rfkill-unblock = {
      description = "Unblock Bluetooth via rfkill";
      after = ["bluetooth.service"];
      requires = ["bluetooth.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe' pkgs.util-linux "rfkill"} unblock bluetooth";
      };
    };

    services.blueman.enable = true;

    # BT Consumer Control HID devices expose KEY_POWER; on disconnect the
    # key-down fires without a matching key-up, so logind interprets it as
    # a long-press and powers off. Strip ID_INPUT_KEY so logind ignores them.
    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "bt-consumer-control-no-power";
        destination = "/etc/udev/rules.d/65-bt-consumer-control-no-power.rules";
        text = ''
          SUBSYSTEM=="input", ATTR{name}=="*Consumer Control*", ATTR{id/bustype}=="0003", ENV{ID_INPUT_KEY}=""
        '';
      })
    ];

    # Ignore power-key events via logind (defense-in-depth for BT disconnect).
    services.logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "ignore";
    };
  };
}
