{ config, ... }:
{
  # Configure ACME appropriately
  security.acme.acceptTerms = true;
  security.acme.defaults = {
    email = "felix.plamper@tuta.io";
    dnsResolver = "1.1.1.1:53";
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets."cloudflare-token".path;
    extraLegoFlags = [ "--dns.propagation-wait=15s" ]; # Dns Propagation check does not work
  };

  # For each virtual host you would like to use DNS-01 validation with,
  # set acmeRoot = null

  # Open nginx firewall Ports 
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "bodenlos-schlem.men" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:7575";
        };
      };

      "nextcloud.bodenlos-schlem.men" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = "http://192.168.100.11";
          # Upload large files to nextcloud
          proxyWebsockets = true;
          extraConfig = "
            client_max_body_size 512m;
          ";
        };
      };
      "office.bodenlos-schlem.men" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = "http://192.168.100.11";
          proxyWebsockets = true;
        };
      };

      "jellyfin.bodenlos-schlem.men" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/" = {

          proxyPass = "http://192.168.100.13:8096";
          proxyWebsockets = true; # needed if you need to use WebSocket
          # extraConfig =
          #   # required when the target is also TLS server with multiple hosts
          #   "proxy_ssl_server_name on;" +
          #   # required when the server wants to use HTTP Authentication
          #   "proxy_pass_header Authorization;"
          # ;
        };
      };
      "arr.bodenlos-schlem.men" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/transmission" = {
          proxyPass = "http://127.0.0.1:9091/transmission";
          proxyWebsockets = true;
          recommendedProxySettings = false;
        };

        # Url Base Has to be manually modified in webui settings under General/URL Base
        locations."/sonarr" = {
          proxyPass = "http://127.0.0.1:8989/sonarr";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_pass_header Authorization;
          '';
        };
        locations."/sonarr/api" = {
          proxyPass = "http://127.0.0.1:8989";
          recommendedProxySettings = false;
          extraConfig = ''
            auth_basic off;
          '';
        };
      };

      # Grafana Virtual Host
      ${config.services.grafana.settings.server.domain} = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
        };
      };
    };
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "418e37a3-68a1-43e4-949b-a1f38ff4d9b7" = {
        credentialsFile = config.age.secrets.cloudflared-creds.path;
        default = "http_status:404";
      };
    };
  };
}

