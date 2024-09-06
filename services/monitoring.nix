{ config, pkgs, ... }:
{
  # grafana configuration
  services.grafana = {
    enable = true;
    settings.server = {
      domain = "grafana.bodenlos-schlem.men";
      http_port = 2342;
      http_addr = "127.0.0.1";
    };
  };

  services.prometheus = {
    enable = true;
    port = 9001;
    scrapeConfigs = [
      {
        job_name = "nix-nas";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
      {
        job_name = "nextcloud";
        static_configs = [{
          targets = [ "192.168.100.11:9000" ];
        }];
      }
    ];

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
  };
}
