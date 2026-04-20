# Metrics collection - node-exporter + remote-write agent (vmagent).
# Builds on the existing monitoring scope for node-exporter defaults.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.o11y.metrics;
  exporters = config.services.prometheus.exporters;
in {
  imports = [../monitoring];

  options.nixfleet.o11y.metrics = {
    enable = lib.mkEnableOption "metrics collection and remote-write shipping";

    serverUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Remote-write endpoint URL (e.g., VictoriaMetrics, Mimir, Thanos).
        When null, only local exporters are enabled (no shipping).
      '';
    };

    exporters = {
      node = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Prometheus node exporter.";
      };

      scaphandre = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Scaphandre power/electricity exporter.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.exporters.node {
      nixfleet.monitoring.nodeExporter.enable = true;
    })

    (lib.mkIf cfg.exporters.scaphandre {
      services.prometheus.exporters.scaphandre.enable = true;
    })

    (lib.mkIf (cfg.serverUrl != null) {
      services.vmagent = {
        enable = true;
        remoteWrite.url = cfg.serverUrl;
        prometheusConfig = {
          scrape_configs =
            lib.mapAttrsToList
            (job_name: expCfg: {
              inherit job_name;
              static_configs = [{targets = ["127.0.0.1:${builtins.toString expCfg.port}"];}];
            })
            (lib.filterAttrs
              (name: expCfg:
                expCfg.enable
                && !(builtins.elem name [
                  "assertions"
                  "warnings"
                ]))
              exporters);
          global = {
            scrape_interval = "15s";
            external_labels.hostname = config.networking.hostName;
          };
        };
      };
    })
  ]);
}
