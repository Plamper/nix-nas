{ config, pkgs, lib, ... }:
let
  domain = "vpn.plamper.org";
in
{
  age.secrets."kanidm-headscale-oidc-secret" = {
    file = ../../secrets/kanidm-headscale-oidc-secret.age;
    group = "headscale";
    mode = "440";
  };
  age.secrets."kanidm-headplane-oidc-secret" = {
    file = ../../secrets/kanidm-headplane-oidc-secret.age;
    group = "headscale";
    mode = "440";
  };
  age.secrets."headscale-api-key" = {
    file = ../../secrets/headscale-api-key.age;
    group = "headscale";
    mode = "440";
  };
  age.secrets."headplane-cookie-secret" = {
    file = ../../secrets/headplane-cookie-secret.age;
    group = "headscale";
    mode = "440";
  };

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 8081;

    settings = {
      server_url = "https://${domain}";

      dns = {
        magic_dns = true;
        base_domain = "internal.plamper.org";
        override_local_dns = true;
        nameservers.global = [
          "1.1.1.1"
          "9.9.9.9"
        ];

        extra_records = [
          {
            name = "jellyfin.plamper.org";
            type = "A";
            value = "100.64.0.3";
          }
          {
            name = "cloud.plamper.org";
            type = "A";
            value = "100.64.0.3";
          }
          {
            name = "idm.plamper.org";
            type = "A";
            value = "100.64.0.3";
          }
          {
            name = "sonarr.plamper.org";
            type = "A";
            value = "100.64.0.3";
          }
          {
            name = "transmission.plamper.org";
            type = "A";
            value = "100.64.0.3";
          }
          {
            name = "auth.plamper.org";
            type = "A";
            value = "100.64.0.3";
          }
          {
            name = "grafana.plamper.org";
            type = "A";
            value = "100.64.0.3";
          }
          {
            name = "pass.plamper.org";
            type = "A";
            value = "100.64.0.3";
          }
        ];
      };

      oidc = {
        issuer = "https://idm.plamper.org/oauth2/openid/headscale";
        client_id = "headscale";
        client_secret_path = config.age.secrets."kanidm-headscale-oidc-secret".path;
        scope = [
          "openid"
          "profile"
          "email"
        ];
        pkce.enabled = true;
      };
    };
  };

  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = 3000;
        cookie_secret_path = config.age.secrets."headplane-cookie-secret".path;
        cookie_secure = true;
        base_url = "https://${domain}";
      };

      headscale.url = "https://${domain}";

      oidc = {
        issuer = "https://idm.plamper.org/oauth2/openid/headplane";
        client_id = "headplane";
        client_secret_path = config.age.secrets."kanidm-headplane-oidc-secret".path;
        headscale_api_key_path = config.age.secrets."headscale-api-key".path;
        token_endpoint_auth_method = "client_secret_post";
        use_pkce = true;
        disable_api_key_login = true;
      };
    };
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:8081";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
      "/admin/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
  };

  environment.systemPackages = [ config.services.headscale.package ];
}
