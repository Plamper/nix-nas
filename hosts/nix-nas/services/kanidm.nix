{
  config,
  pkgs,
  ...
}:
{

  age.secrets."kanidm-admin-password" = {
    file = ../../../secrets/kanidm-admin-password.age;
    group = "kanidm";
    mode = "440";
  };
  age.secrets."kanidm-idm-admin-password" = {
    file = ../../../secrets/kanidm-idm-admin-password.age;
    group = "kanidm";
    mode = "440";
  };
  age.secrets."kanidm-mail-sender-config" = {
    file = ../../../secrets/kanidm-mail-sender-config.age;
    group = "kanidm";
    mode = "440";
  };
  age.secrets."kanidm-nextcloud-oidc-secret" = {
    file = ../../../secrets/kanidm-nextcloud-oidc-secret.age;
    group = "kanidm";
    mode = "440";
  };
  age.secrets."kanidm-headscale-oidc-secret" = {
    file = ../../../secrets/kanidm-headscale-oidc-secret.age;
    group = "kanidm";
    mode = "440";
  };
  age.secrets."kanidm-headplane-oidc-secret" = {
    file = ../../../secrets/kanidm-headplane-oidc-secret.age;
    group = "kanidm";
    mode = "440";
  };
  age.secrets."kanidm-oauth2-proxy-oidc-secret" = {
    file = ../../../secrets/kanidm-oauth2-proxy-oidc-secret.age;
    group = "kanidm";
    mode = "440";
  };
  age.secrets."oauth2-proxy-oidc-secret" = {
    file = ../../../secrets/oauth2-proxy-oidc-secret.age;
    owner = "oauth2-proxy";
  };
  age.secrets."oauth2-proxy-cookie-secret" = {
    file = ../../../secrets/oauth2-proxy-cookie-secret.age;
    owner = "oauth2-proxy";
  };

  services.kanidm.package = pkgs.kanidmWithSecretProvisioning_1_11;
  services.kanidm.server = {
    enable = true;
    settings = {
      domain = "idm.plamper.org";
      origin = "https://idm.plamper.org";
      bindaddress = "127.0.0.1:8443";
      ldapbindaddress = "0.0.0.0:636";
      tls_chain = "/var/lib/acme/idm.plamper.org/fullchain.pem";
      tls_key = "/var/lib/acme/idm.plamper.org/key.pem";
      online_backup = {
        path = "/mnt/data-pool/Backup/kanidm";
      };
    };
  };
  services.kanidm.client = {
    enable = true;
    settings.uri = "https://idm.plamper.org";
  };

  # access to acme certificates
  users.users.kanidm.extraGroups = [ "nginx" ];

  systemd.tmpfiles.rules = [
    "d /mnt/data-pool/Backup/kanidm 0750 kanidm kanidm -"
  ];

  services.kanidm.provision = {
    enable = true;
    instanceUrl = "https://localhost:8443";
    adminPasswordFile = config.age.secrets."kanidm-admin-password".path;
    idmAdminPasswordFile = config.age.secrets."kanidm-idm-admin-password".path;

    groups = {
      "nextcloud_users".overwriteMembers = false;
      "vpn_users".overwriteMembers = false;
      "vpn_admins".overwriteMembers = false;
      "forward_auth_users".overwriteMembers = false;
      "arr_users".overwriteMembers = false;
      "jellyfin_users".overwriteMembers = false;
    };
    systems.oauth2 = {
      "nextcloud" = {
        displayName = "Nextcloud";
        originUrl = "https://cloud.plamper.org/apps/user_oidc/code";
        originLanding = "https://cloud.plamper.org/";
        basicSecretFile = config.age.secrets."kanidm-nextcloud-oidc-secret".path;
        preferShortUsername = true;
        scopeMaps = {
          "nextcloud_users" = [
            "openid"
            "profile"
            "email"
          ];
        };
      };
      "headscale" = {
        displayName = "Headscale";
        originUrl = "https://vpn.plamper.org/oidc/callback";
        originLanding = "https://vpn.plamper.org/";
        basicSecretFile = config.age.secrets."kanidm-headscale-oidc-secret".path;
        preferShortUsername = true;
        scopeMaps = {
          "vpn_users" = [
            "openid"
            "profile"
            "email"
          ];
        };
      };
      "headplane" = {
        displayName = "Headplane";
        originUrl = "https://vpn.plamper.org/admin/oidc/callback";
        originLanding = "https://vpn.plamper.org/admin/";
        basicSecretFile = config.age.secrets."kanidm-headplane-oidc-secret".path;
        preferShortUsername = true;
        scopeMaps."vpn_admins" = [
          "openid"
          "profile"
          "email"
        ];
      };
      "oauth2-proxy" = {
        displayName = "OAuth2 Proxy (Forward Auth)";
        originUrl = "https://auth.plamper.org/oauth2/callback";
        originLanding = "https://auth.plamper.org/";
        basicSecretFile = config.age.secrets."kanidm-oauth2-proxy-oidc-secret".path;
        scopeMaps = {
          "forward_auth_users" = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
        };
      };
    };
  };

  systemd.services."kanidm-mail-sender" = {
    description = "Kanidm Mail Sender";
    after = [
      "kanidm.service"
      "network-online.target"
    ];
    wants = [
      "network-online.target"
      "kanidm.service"
    ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "kanidm";
      Group = "kanidm";
      ExecStart = "${config.services.kanidm.package}/bin/kanidm-mail-sender -m ${
        config.age.secrets."kanidm-mail-sender-config".path
      }";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # wait for kanidm before starting oauth2-proxy
  systemd.services.oauth2-proxy = {
    after = [ "kanidm.service" ];
    wants = [ "kanidm.service" ];
    serviceConfig.RestartSec = "10s";
  };

  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    oidcIssuerUrl = "https://idm.plamper.org/oauth2/openid/oauth2-proxy";
    clientID = "oauth2-proxy";
    keyFile = config.age.secrets."oauth2-proxy-oidc-secret".path;

    cookie.domain = ".plamper.org";
    cookie.secretFile = config.age.secrets."oauth2-proxy-cookie-secret".path;

    email.domains = [ "*" ];
    setXauthrequest = true;
    reverseProxy = true;
    trustedProxyIP = [
      "127.0.0.1/32"
      "::1/128"
    ];
    httpAddress = "127.0.0.1:4180";
    redirectURL = "https://auth.plamper.org/oauth2/callback";
    nginx = {
      domain = "auth.plamper.org";
      proxy = "http://127.0.0.1:4180";
    };

    extraConfig = {
      scope = "openid email profile groups";
      oidc-groups-claim = "groups";
      skip-provider-button = "true";
      whitelist-domain = ".plamper.org";
      code-challenge-method = "S256";
    };
  };

  services.nginx.virtualHosts."idm.plamper.org" = {
    enableACME = true;
    forceSSL = true;
    acmeRoot = null;
    locations."/" = {
      proxyPass = "https://localhost:8443";
      extraConfig = ''
        proxy_ssl_server_name on;
      '';
    };
  };
  services.nginx.virtualHosts."auth.plamper.org" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    extraConfig = ''
      proxy_buffer_size   16k;
      proxy_buffers       4 16k;
      proxy_busy_buffers_size 16k;
    '';
  };
}
