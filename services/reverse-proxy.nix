{ config, ... }:
{
  # Configure ACME appropriately
  # security.acme.acceptTerms = true;
  # security.acme.defaults = {
  #   email = "felix.plamper@tuta.io";
  #   dnsResolver = "1.1.1.1:53";
  #   dnsProvider = "cloudflare";
  #   environmentFile = config.age.secrets."cloudflare-token".path;
  # };

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
        locations."/" = {
          proxyPass = "http://127.0.0.1:7575";
        };
      };

      "test-nextcloud.bodenlos-schlem.men" = {
        # enableACME = true;
        # acmeRoot = null;
        # forceSSL = true;
        locations."/" = {

          proxyPass = "http://192.168.100.11";
          # proxyWebsockets = true; # needed if you need to use WebSocket
          # extraConfig =
          #   # required when the target is also TLS server with multiple hosts
          #   "proxy_ssl_server_name on;" +
          #   # required when the server wants to use HTTP Authentication
          #   "proxy_pass_header Authorization;"
          # ;
        };
      };
      "test-jellyfin.bodenlos-schlem.men" = {
        # enableACME = true;
        # acmeRoot = null;
        # forceSSL = true;
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
      "test-arr.bodenlos-schlem.men" = {
        # enableACME = true;
        # acmeRoot = null;
        # forceSSL = true;
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
        # enableACME = true;
        # acmeRoot = null;
        # forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}

