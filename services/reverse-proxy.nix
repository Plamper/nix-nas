{ config, ... }:
{
  # Configure ACME appropriately
  # security.acme.acceptTerms = true;
  # security.acme.defaults.email = "felix.plamper@tuta.io";
  # security.acme.defaults = {
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

          proxyPass = "http://192.168.100.13:8020";
          proxyWebsockets = true; # needed if you need to use WebSocket
          # extraConfig =
          #   # required when the target is also TLS server with multiple hosts
          #   "proxy_ssl_server_name on;" +
          #   # required when the server wants to use HTTP Authentication
          #   "proxy_pass_header Authorization;"
          # ;
        };
      };
    };
  };
}

