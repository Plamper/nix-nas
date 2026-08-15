{ config, ... }:
{
  services.grafana = {
    enable = true;
    settings.security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
    settings.server = {
      domain = "grafana.plamper.org";
      http_port = 3000;
      http_addr = "127.0.0.1";
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };
  };

  services.nginx.virtualHosts.${config.services.grafana.settings.server.domain} = {
    enableACME = true;
    acmeRoot = null;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
    };
  };

  services.prometheus.exporters.smartctl.enable = true;

  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9633 ];

  services.prometheus = {
    enable = true;
    port = 9001;
    scrapeConfigs = [
      {
        job_name = "node-nix-nas";
        static_configs = [
          {
            targets = [ "127.0.0.1:9100" ];
            labels.host = "nix-nas";
          }
        ];
      }
      {
        job_name = "node-cloudnix";
        static_configs = [
          {
            targets = [ "10.20.0.1:9100" ];
            labels.host = "cloudnix";
          }
        ];
      }
      {
        job_name = "nginx";
        static_configs = [
          {
            targets = [ "10.20.0.2:9113" ];
            labels.host = "nix-nas";
          }
          {
            targets = [ "10.20.0.1:9113" ];
            labels.host = "cloudnix";
          }
        ];
      }
      {
        job_name = "postfix";
        static_configs = [
          {
            targets = [ "10.20.0.1:9154" ];
            labels.host = "cloudnix";
          }
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          {
            targets = [ "10.20.0.2:9633" ];
            labels.host = "nix-nas";
          }
        ];
      }
    ];
  };

  # loki: port 3030 (8030)
  #
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3030;
      auth_enabled = false;

      common = {
        instance_addr = "127.0.0.1";
        path_prefix = "/var/lib/loki/";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
      };

      schema_config = {
        configs = [
          {
            from = "2020-10-24";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
    };
    # user, group, dataDir, extraFlags, (configFile)
  };

  # promtail: port 3031 (8031)
  # TODO: Replace with grafana alloy
  # services.promtail = {
  #   enable = true;
  #   configuration = {
  #     server = {
  #       http_listen_port = 3031;
  #       grpc_listen_port = 0;
  #     };
  #     positions = {
  #       filename = "/tmp/positions.yaml";
  #     };
  #     clients = [{
  #       url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
  #     }];
  #     scrape_configs = [{
  #       job_name = "journal";
  #       journal = {
  #         max_age = "12h";
  #         labels = {
  #           job = "systemd-journal";
  #           host = "nix-nas";
  #         };
  #       };
  #       relabel_configs = [{
  #         source_labels = [ "__journal__systemd_unit" ];
  #         target_label = "unit";
  #       }];
  #     }];
  #   };
  # };
}
