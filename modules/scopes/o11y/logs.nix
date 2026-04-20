# Log shipping - systemd-journal-upload to remote server.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.o11y.logs;
in {
  options.nixfleet.o11y.logs = {
    enable = lib.mkEnableOption "log shipping to remote server";

    serverUrl = lib.mkOption {
      type = lib.types.str;
      description = "systemd-journal-upload target URL.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.journald.upload = {
      enable = true;
      settings.Upload.URL = cfg.serverUrl;
    };
  };
}
