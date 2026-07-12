{

  services.nginx = {
    enable = true;

    virtualHosts = {
      "photos.plamper.org" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;

        locations."/" = {
          proxyPass = "http://10.20.0.2:2283";
          # 10.20.0.2 is nix-nas via WireGuard tunnel
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            # Proper headers for Immich
            proxy_buffering off;
            proxy_request_buffering off;

            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
          '';
        };
      };
    };
  };

  # Security settings for the reverse proxy
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };

}
