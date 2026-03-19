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
    lldap_user_pass_authelia = {
      file = ../../../secrets/lldap_user_pass.age;
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
    };
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.age.secrets.lldap_user_pass_authelia.path;
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

      authentication_backend = {
        ldap = {
          address = "ldap://127.0.0.1:${toString config.services.lldap.settings.ldap_port}";
          implementation = "lldap";
          base_dn = config.services.lldap.settings.ldap_base_dn;
          users_filter = "(&({username_attribute}={input})(objectClass=person))";
          groups_filter = "(&(member={dn})(objectClass=groupOfNames))";
          user = "cn=admin,ou=people,dc=plamper,dc=org";
        };
      };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = [ "auth.plamper.org" ];
            policy = "bypass";
          }
          {
            domain = [ "*.plamper.org" ];
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
        filesystem = {
          filename = "/var/lib/authelia-main/notification.txt";
        };
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
  services.nginx.virtualHosts."auth.plamper.org" = {
    enableACME = true;
    forceSSL = true;
    acmeRoot = null;

    locations."/" = {
      proxyPass = "http://127.0.0.1:9091";
      proxyWebsockets = true;
    };
  };
}
