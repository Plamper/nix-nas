{ config, ... }:
let
  securityHeaders = ''
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  '';
in
{

  # For each virtual host you would like to use DNS-01 validation with,
  # set acmeRoot = null

  services.nginx = {
    virtualHosts = {

      "cloud.plamper.org" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = "http://192.168.100.11";
          # Upload large files to nextcloud
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 512m;
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
          '';
        };
      };
      "office.plamper.org" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = "http://127.0.0.1:7979";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 100m;
            add_header Content-Security-Policy "frame-ancestors 'self' https://cloud.plamper.org;" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header Referrer-Policy "strict-origin-when-cross-origin" always;
          '';
        };
      };
      "typst.plamper.org" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8978";
          proxyWebsockets = true;
          extraConfig = securityHeaders;
        };
      };

      "jellyfin.plamper.org" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/" = {

          proxyPass = "http://192.168.100.13:8096";
          proxyWebsockets = true; # needed if you need to use WebSocket
          extraConfig = securityHeaders;
          # extraConfig =
          #   # required when the target is also TLS server with multiple hosts
          #   "proxy_ssl_server_name on;" +
          #   # required when the server wants to use HTTP Authentication
          #   "proxy_pass_header Authorization;"
          # ;
        };
      };
      "192.168.178.141" = {
        locations."/" = {

          proxyPass = "http://192.168.100.13:8096";
          proxyWebsockets = true; # needed if you need to use WebSocket
          extraConfig = securityHeaders;
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

  services.cloudflared = {
    enable = true;
    tunnels = {
      "418e37a3-68a1-43e4-949b-a1f38ff4d9b7" = {
        credentialsFile = config.age.secrets.cloudflared-creds.path;
        default = "http_status:404";
      };
    };
  };

  systemd.services."cloudflared-tunnel-418e37a3-68a1-43e4-949b-a1f38ff4d9b7".serviceConfig = {
    PrivateUsers = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    RemoveIPC = true;
    ProtectKernelLogs = true;
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    MemoryDenyWriteExecute = true;
    LockPersonality = true;
    CapabilityBoundingSet = "";
    ProtectClock = true;
    ProtectHostname = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@privileged"
    ];
  };
}
