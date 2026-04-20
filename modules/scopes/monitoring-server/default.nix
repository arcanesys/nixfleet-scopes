# Prometheus server with fleet-tuned defaults and basic alert rules.
#
# Provides a ready-to-use Prometheus instance for fleet monitoring.
# Consumers add scrape targets via nixfleet.monitoring.server.scrapeConfigs
# or let the scope auto-discover node-exporter targets from a static list.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.monitoring.server;
  impermanenceEnabled = config.nixfleet.impermanence.enable or false;

  builtinAlerts = {
    groups = [
      {
        name = "nixfleet";
        rules =
          [
            {
              alert = "HostDown";
              expr = "up == 0";
              "for" = "1m";
              labels.severity = "critical";
              annotations.summary = "{{ $labels.instance }} is unreachable";
            }
            {
              alert = "DiskSpaceHigh";
              expr = ''node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} < 0.2'';
              "for" = "5m";
              labels.severity = "warning";
              annotations.summary = "{{ $labels.instance }} root disk > 80% full";
            }
            {
              alert = "SystemdUnitFailed";
              expr = ''node_systemd_unit_state{state="failed"} == 1'';
              "for" = "1m";
              labels.severity = "warning";
              annotations.summary = "{{ $labels.name }} failed on {{ $labels.instance }}";
            }
          ]
          ++ lib.optionals cfg.alerts.controlPlane [
            {
              alert = "ControlPlaneDown";
              expr = ''up{job="nixfleet-cp"} == 0'';
              "for" = "1m";
              labels.severity = "critical";
              annotations.summary = "NixFleet control plane is unreachable";
            }
          ];
      }
    ];
  };
in {
  options.nixfleet.monitoring.server = {
    enable = lib.mkEnableOption "Prometheus server with fleet defaults";

    port = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Prometheus listen port.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Prometheus listen address. Use 0.0.0.0 to expose externally.";
    };

    retentionTime = lib.mkOption {
      type = lib.types.str;
      default = "30d";
      description = "TSDB retention period.";
    };

    scrapeInterval = lib.mkOption {
      type = lib.types.str;
      default = "15s";
      description = "Global scrape interval.";
    };

    targets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Static node-exporter targets (e.g., ["web-01:9100" "db-01:9100"]).
        Auto-generates a "node" scrape job.
      '';
    };

    extraScrapeConfigs = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Additional Prometheus scrape configs (appended to built-in ones).";
    };

    alerts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable built-in alert rules (HostDown, DiskSpaceHigh, SystemdUnitFailed).";
      };

      controlPlane = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Add ControlPlaneDown alert (requires a nixfleet-cp scrape job).";
      };

      extraRuleFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = "Additional Prometheus rule files.";
      };
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open Prometheus port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.prometheus = {
        enable = true;
        port = cfg.port;
        listenAddress = cfg.listenAddress;
        globalConfig.scrape_interval = cfg.scrapeInterval;
        checkConfig = "syntax-only";
        retentionTime = cfg.retentionTime;

        ruleFiles =
          (lib.optional cfg.alerts.enable
            (builtins.toFile "nixfleet-alerts.yml" (builtins.toJSON builtinAlerts)))
          ++ cfg.alerts.extraRuleFiles;

        scrapeConfigs =
          (lib.optional (cfg.targets != []) {
            job_name = "node";
            static_configs = [{targets = cfg.targets;}];
          })
          ++ cfg.extraScrapeConfigs;
      };
    }

    (lib.mkIf cfg.openFirewall {
      networking.firewall.allowedTCPPorts = [cfg.port];
    })

    # Persist TSDB across reboots on impermanent hosts
    (lib.mkIf impermanenceEnabled {
      environment.persistence."/persist".directories = [
        {
          directory = "/var/lib/prometheus2";
          user = "prometheus";
          group = "prometheus";
          mode = "0700";
        }
      ];
    })
  ]);
}
