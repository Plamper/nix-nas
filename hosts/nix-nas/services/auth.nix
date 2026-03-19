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
  };

  services.lldap = {
    enable = true;
    settings = {
      ldap_base_dn = "dc=bodenlos-schlem,dc=men";
      http_url = "https://lldap.bodenlos-schlem.men";
      database_url = "postgres:///lldap?host=/var/run/postgresql/";
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
      "authelia"
    ];
    ensureUsers = [
      {
        name = "lldap";
        ensureDBOwnership = true;
      }
      {
        name = "authelia";
        ensureDBOwnership = true;
      }
    ];
  };

  services.nginx.virtualHosts = {
    "lldap.bodenlos-schlem.men" = {
      enableACME = true;
      acmeRoot = null;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.lldap.settings.http_port}";
      };
    };
  };

  # services.authelia.instances.main = {
  #   enable = true;
  #   user = "authelia";
  #   secrets = {
  #     jwtSecretFile = "${pkgs.writeText "jwtSecretFile" "supersecretkey"}";
  #     storageEncryptionKeyFile = "${pkgs.writeText "storageEncryptionKeyFile" "supersecretkey"}";
  #     sessionSecretFile = "${pkgs.writeText "sessionSecretFile" "supersecretkey"}";
  #   };
  #   settings = {
  #     theme = "dark";
  #     default_redirection_url = "https://nextcloud.bodenlos-schlem.men";

  #     server = {
  #       host = "127.0.0.1";
  #       port = 9091;
  #     };

  #     log = {
  #       level = "debug";
  #       format = "text";
  #     };

  #     authentication_backend = {
  #       ldap = {
  #         address = "ldaps://127.0.0.1:${toString config.services.lldap.settings.ldap_port}";
  #         implementation = "lldap";
  #         base_dn = config.services.lldap.settings.ldap_base_dn;
  #         users_filter = "(&({username_attribute}={input})(objectClass=person))";
  #         groups_filter = "(&(member={dn})(objectClass=groupOfNames))";
  #         user = "cn=admin,dc=bodenlos-schlem,dc=men";
  #       };
  #     };

  #     access_control = {
  #       default_policy = "deny";
  #       rules = [
  #         {
  #           domain = [ "auth.example.com" ];
  #           policy = "bypass";
  #         }
  #         {
  #           domain = [ "*.example.com" ];
  #           policy = "one_factor";
  #         }
  #       ];
  #     };

  #     session = {
  #       name = "authelia_session";
  #       expiration = "24h";
  #       inactivity = "2h";
  #       remember_me_duration = "1M";
  #       domain = "bodenlos-schlem.men";
  #       redis.host = "/run/redis-authelia-main/redis.sock";
  #     };

  #     regulation = {
  #       max_retries = 3;
  #       find_time = "5m";
  #       ban_time = "15m";
  #     };

  #     storage.postgres = {
  #       address = "unix:///run/postgresql";
  #       database = "authelia";
  #       username = "authelia";
  #       # Not used but has to be set
  #       password = "authelia";
  #     };

  #     notifier = {
  #       disable_startup_check = false;
  #       filesystem = {
  #         filename = "/var/lib/authelia-main/notification.txt";
  #       };
  #     };
  #   };
  # };
  # services.redis.servers.authelia-main = {
  #   enable = true;
  #   user = "authelia-main";
  #   port = 0;
  #   unixSocket = "/run/redis-authelia-main/redis.sock";
  #   unixSocketPerm = 600;
  # };
  # services.nginx.virtualHosts."auth.bodenlos-schlem.men" = {
  #   enableACME = true;
  #   forceSSL = true;
  #   acmeRoot = null;

  #   locations."/" = {
  #     proxyPass = "http://127.0.0.1:${toString config.services.authelia.instances.main.settings.server.port}";
  #     proxyWebsockets = true;
  #   };
  # };
}
