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

      "nextcloud.bodenlos-schlem.men" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = "https://10.20.0.2";
          # Upload large files to nextcloud
          extraConfig = "
            client_max_body_size 512m;
          ";
        };
      };

    };
  };
}

