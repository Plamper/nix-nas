{
  config,
  pkgs,
  lib,
  ...
}:
{
  age.secrets = {
    lldap_jwt_secret = {
      file = ../../../secrets/lldap_jwt_secret.age;
      group = "lldap-secrets";
      mode = "440";
    };
    lldap_user_pass = {
      file = ../../../secrets/lldap_user_pass.age;
      group = "lldap-secrets";
      mode = "440";
    };
    authelia-jwt = {
      file = ../../../secrets/authelia-jwt.age;
      group = config.services.authelia.instances.main.group;
      mode = "440";
    };
    authelia-storageEncryptionKey = {
      file = ../../../secrets/authelia-storageEncryptionKey.age;
      group = config.services.authelia.instances.main.group;
      mode = "440";
    };
    authelia-sessionSecret = {
      file = ../../../secrets/authelia-sessionSecret.age;
      group = config.services.authelia.instances.main.group;
      mode = "440";
    };
    authelia-oidcHmacSecret = {
      file = ../../../secrets/authelia-oidcHmacSecret.age;
      group = config.services.authelia.instances.main.group;
      mode = "440";
    };
    authelia-oidcIssuerPrivateKey = {
      file = ../../../secrets/authelia-oidcIssuerPrivateKey.age;
      group = config.services.authelia.instances.main.group;
      mode = "440";
    };
    lldap_user_pass_authelia = {
      file = ../../../secrets/lldap_user_pass.age;
      group = config.services.authelia.instances.main.group;
      mode = "440";
    };
    authelia-smtp-password = {
      file = ../../../secrets/noreply-smtp-password.age;
      group = config.services.authelia.instances.main.group;
      mode = "440";
    };
  };

  services.lldap = {
    enable = true;
    settings = {
      ldap_base_dn = "dc=plamper,dc=org";
      http_url = "https://lldap.plamper.org";
      database_url = "postgres:///lldap?host=/var/run/postgresql/";
      force_ldap_user_pass_reset = "always";
    };
    environment = {
      LLDAP_JWT_SECRET_FILE = config.age.secrets.lldap_jwt_secret.path;
      LLDAP_LDAP_USER_PASS_FILE = config.age.secrets.lldap_user_pass.path;
    };
  };

  networking.firewall.interfaces."wg0".allowedTCPPorts = [ 3890 ];

  users.groups.lldap-secrets.name = "lldap-secrets";
  systemd.services.lldap.serviceConfig.SupplementaryGroups = [ "lldap-secrets" ];

  services.postgresql = {
    ensureDatabases = [
      "lldap"
      config.services.authelia.instances.main.user
    ];
    ensureUsers = [
      {
        name = "lldap";
        ensureDBOwnership = true;
      }
      {
        name = config.services.authelia.instances.main.user;
        ensureDBOwnership = true;
      }
    ];
  };

  services.nginx.virtualHosts = {
    "lldap.plamper.org" = {
      enableACME = true;
      acmeRoot = null;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.lldap.settings.http_port}";
      };
    };
  };

  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = config.age.secrets.authelia-jwt.path;
      storageEncryptionKeyFile = config.age.secrets.authelia-storageEncryptionKey.path;
      sessionSecretFile = config.age.secrets.authelia-sessionSecret.path;
      oidcIssuerPrivateKeyFile = config.age.secrets.authelia-oidcIssuerPrivateKey.path;
      oidcHmacSecretFile = config.age.secrets.authelia-oidcHmacSecret.path;
    };
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE =
        config.age.secrets.lldap_user_pass_authelia.path;
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets.authelia-smtp-password.path;
    };
    settings = {
      theme = "dark";
      default_2fa_method = "";

      server = {
        address = "tcp://127.0.0.1:9091";
      };

      log = {
        level = "debug";
        format = "text";
      };

      authentication_backend.ldap = {
        address = "ldap://127.0.0.1:${toString config.services.lldap.settings.ldap_port}";
        implementation = "lldap";
        base_dn = config.services.lldap.settings.ldap_base_dn;
        users_filter = "(&({username_attribute}={input})(objectClass=person))";
        groups_filter = "(&(member={dn})(objectClass=groupOfNames))";
        user = "cn=admin,ou=people,dc=plamper,dc=org";
        attributes = {
          extra = {
            mailboxaddress = {
              name = "mailboxaddress";
              multi_valued = false;
              value_type = "string";
            };
          };
        };
      };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = [
              "auth.plamper.org"
              "auth.bodenlos-schlem.men"
            ];
            policy = "bypass";
          }
          # Allow arr_users to access transmission and sonarr
          {
            domain = [
              "transmission.bodenlos-schlem.men"
              "sonarr.bodenlos-schlem.men"
            ];
            subject = [ "group:arr_users" ];
            policy = "one_factor";
          }
          # Deny access to transmission and sonarr for all users
          {
            domain = [
              "transmission.bodenlos-schlem.men"
              "sonarr.bodenlos-schlem.men"
            ];
            policy = "deny";
          }
          {
            domain = [
              "*.plamper.org"
              "*.bodenlos-schlem.men"
            ];
            policy = "one_factor";
          }
        ];
      };

      session = {
        name = "authelia_session";
        expiration = "24h";
        inactivity = "2h";
        cookies = [
          {
            domain = "plamper.org";
            authelia_url = "https://auth.plamper.org";
            remember_me = "1M";
          }
          {
            domain = "bodenlos-schlem.men";
            authelia_url = "https://auth.bodenlos-schlem.men";
            remember_me = "1M";
          }
        ];
        redis.host = "/run/redis-authelia-main/redis.sock";
      };

      regulation = {
        max_retries = 3;
        find_time = "5m";
        ban_time = "15m";
      };

      storage.postgres = {
        address = "unix:///run/postgresql";
        database = config.services.authelia.instances.main.user;
        username = config.services.authelia.instances.main.user;
        # Not used but has to be set
        password = config.services.authelia.instances.main.user;
      };

      notifier = {
        disable_startup_check = false;
        smtp = {
          address = "submissions://mail.plamper.org:465";
          username = "noreply@plamper.org";
          sender = "Authelia <noreply@plamper.org>";
          subject = "[Authelia] {title}";
          timeout = "30s";
        };
      };

      identity_providers.oidc = {
        claims_policies = {
          nextcloud = {
            custom_claims = {
              mailboxaddress = {
                attribute = "mailboxaddress";
              };
            };
          };
        };
        scopes = {
          mailbox = {
            claims = [ "mailboxaddress" ];
          };
        };
        cors.endpoints = [
          "authorization"
          "token"
          "revocation"
          "introspection"
          "userinfo"
        ];
        clients = [
          {
            client_id = "nextcloud";
            client_name = "Nextcloud";
            client_secret = "$pbkdf2-sha512$310000$zZ/5Y7RSA4eQ2xgIvilGzQ$u46nQqf6d/MjBAw2atFhsHZE4bAbn4Rd1VQulfg4ciu7.e/vr5zNNcmX7H7RCePfFXRa1dXPhk6p/n5mB/3Xhg"; # hashed secret, see below
            public = false;
            authorization_policy = "one_factor";
            redirect_uris = [ "https://cloud.plamper.org/apps/user_oidc/code" ];
            claims_policy = "nextcloud";
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
              "mailbox"
            ];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_post";
          }
          # {
          #   client_id = "forgejo";
          #   client_name = "Forgejo";
          #   client_secret = "";
          #   public = false;
          #   authorization_policy = "two_factor";
          #   claims_policy = "nextcloud";
          #   scopes = [
          #     "openid"
          #     "profile"
          #     "email"
          #     "groups"
          #     "mailbox"
          #   ];
          #   userinfo_signed_response_alg = "none";
          #   token_endpoint_auth_method = "client_secret_post";
          # }
        ];
      };
    };
  };
  services.redis.servers.authelia-main = {
    enable = true;
    user = "authelia-main";
    port = 0;
    unixSocket = "/run/redis-authelia-main/redis.sock";
    unixSocketPerm = 660;
  };
  services.nginx.virtualHosts = {
    "auth.plamper.org" = {
      enableACME = true;
      forceSSL = true;
      acmeRoot = null;

      locations."/" = {
        proxyPass = "http://127.0.0.1:9091";
        proxyWebsockets = true;
      };
    };
    "auth.bodenlos-schlem.men" = {
      enableACME = true;
      forceSSL = true;
      acmeRoot = null;

      locations."/" = {
        proxyPass = "http://127.0.0.1:9091";
        proxyWebsockets = true;
      };
    };
  };
}
