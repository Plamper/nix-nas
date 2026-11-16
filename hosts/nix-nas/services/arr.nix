{
  config,
  pkgs,
  lib,
  ...
}:
let
  securityHeaders = ''
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  '';
in
{

  age.secrets = {
    "pia" = {
      path = "/run/agenix-containers/arr/pia";
      symlink = false;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "pia-env" = {
      file = ../../../secrets/pia-env.age;
      path = "/run/agenix-containers/arr/pia-env";
      symlink = false;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  systemd.tmpfiles.rules = [
    "d /run/agenix-containers/arr 0700 root root -"
  ];

  systemd.services."container@arr" = {
    unitConfig.RequiresMountsFor = [
      "/mnt/data-pool/media"
      "/run/agenix-containers/arr"
    ];
    serviceConfig = {
      ProtectHome = true;
    };
  };

  services.nginx.virtualHosts."transmission.plamper.org" = {
    enableACME = true;
    acmeRoot = null;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://192.168.100.15:9091";
      extraConfig = ''
        proxy_pass_header X-Transmission-Session-Id;
      ''
      + securityHeaders;
    };
  };
  services.oauth2-proxy.nginx.virtualHosts."transmission.plamper.org" = {
    allowed_groups = [ "arr_users@idm.plamper.org" ];
  };
  services.nginx.virtualHosts."sonarr.plamper.org" = {
    enableACME = true;
    acmeRoot = null;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://192.168.100.15:8989/";
      extraConfig = securityHeaders;
    };
  };
  services.oauth2-proxy.nginx.virtualHosts."sonarr.plamper.org" = {
    allowed_groups = [ "arr_users@idm.plamper.org" ];
  };

  containers.arr =
    let
      hostAddress = "192.168.100.14";
      localAddress = "192.168.100.15";
      vpnProto = "tcp";
      vpnIP = "158.173.21.221";
      vpnPort = "501";
      vpnInterface = "tun0";
      containerInterface = "eth0";
      caCert = ''
        -----BEGIN CERTIFICATE-----
        MIIHqzCCBZOgAwIBAgIJAJ0u+vODZJntMA0GCSqGSIb3DQEBDQUAMIHoMQswCQYD
        VQQGEwJVUzELMAkGA1UECBMCQ0ExEzARBgNVBAcTCkxvc0FuZ2VsZXMxIDAeBgNV
        BAoTF1ByaXZhdGUgSW50ZXJuZXQgQWNjZXNzMSAwHgYDVQQLExdQcml2YXRlIElu
        dGVybmV0IEFjY2VzczEgMB4GA1UEAxMXUHJpdmF0ZSBJbnRlcm5ldCBBY2Nlc3Mx
        IDAeBgNVBCkTF1ByaXZhdGUgSW50ZXJuZXQgQWNjZXNzMS8wLQYJKoZIhvcNAQkB
        FiBzZWN1cmVAcHJpdmF0ZWludGVybmV0YWNjZXNzLmNvbTAeFw0xNDA0MTcxNzQw
        MzNaFw0zNDA0MTIxNzQwMzNaMIHoMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0Ex
        EzARBgNVBAcTCkxvc0FuZ2VsZXMxIDAeBgNVBAoTF1ByaXZhdGUgSW50ZXJuZXQg
        QWNjZXNzMSAwHgYDVQQLExdQcml2YXRlIEludGVybmV0IEFjY2VzczEgMB4GA1UE
        AxMXUHJpdmF0ZSBJbnRlcm5ldCBBY2Nlc3MxIDAeBgNVBCkTF1ByaXZhdGUgSW50
        ZXJuZXQgQWNjZXNzMS8wLQYJKoZIhvcNAQkBFiBzZWN1cmVAcHJpdmF0ZWludGVy
        bmV0YWNjZXNzLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALVk
        hjumaqBbL8aSgj6xbX1QPTfTd1qHsAZd2B97m8Vw31c/2yQgZNf5qZY0+jOIHULN
        De4R9TIvyBEbvnAg/OkPw8n/+ScgYOeH876VUXzjLDBnDb8DLr/+w9oVsuDeFJ9K
        V2UFM1OYX0SnkHnrYAN2QLF98ESK4NCSU01h5zkcgmQ+qKSfA9Ny0/UpsKPBFqsQ
        25NvjDWFhCpeqCHKUJ4Be27CDbSl7lAkBuHMPHJs8f8xPgAbHRXZOxVCpayZ2SND
        fCwsnGWpWFoMGvdMbygngCn6jA/W1VSFOlRlfLuuGe7QFfDwA0jaLCxuWt/BgZyl
        p7tAzYKR8lnWmtUCPm4+BtjyVDYtDCiGBD9Z4P13RFWvJHw5aapx/5W/CuvVyI7p
        Kwvc2IT+KPxCUhH1XI8ca5RN3C9NoPJJf6qpg4g0rJH3aaWkoMRrYvQ+5PXXYUzj
        tRHImghRGd/ydERYoAZXuGSbPkm9Y/p2X8unLcW+F0xpJD98+ZI+tzSsI99Zs5wi
        jSUGYr9/j18KHFTMQ8n+1jauc5bCCegN27dPeKXNSZ5riXFL2XX6BkY68y58UaNz
        meGMiUL9BOV1iV+PMb7B7PYs7oFLjAhh0EdyvfHkrh/ZV9BEhtFa7yXp8XR0J6vz
        1YV9R6DYJmLjOEbhU8N0gc3tZm4Qz39lIIG6w3FDAgMBAAGjggFUMIIBUDAdBgNV
        HQ4EFgQUrsRtyWJftjpdRM0+925Y6Cl08SUwggEfBgNVHSMEggEWMIIBEoAUrsRt
        yWJftjpdRM0+925Y6Cl08SWhge6kgeswgegxCzAJBgNVBAYTAlVTMQswCQYDVQQI
        EwJDQTETMBEGA1UEBxMKTG9zQW5nZWxlczEgMB4GA1UEChMXUHJpdmF0ZSBJbnRl
        cm5ldCBBY2Nlc3MxIDAeBgNVBAsTF1ByaXZhdGUgSW50ZXJuZXQgQWNjZXNzMSAw
        HgYDVQQDExdQcml2YXRlIEludGVybmV0IEFjY2VzczEgMB4GA1UEKRMXUHJpdmF0
        ZSBJbnRlcm5ldCBBY2Nlc3MxLzAtBgkqhkiG9w0BCQEWIHNlY3VyZUBwcml2YXRl
        aW50ZXJuZXRhY2Nlc3MuY29tggkAnS7684Nkme0wDAYDVR0TBAUwAwEB/zANBgkq
        hkiG9w0BAQ0FAAOCAgEAJsfhsPk3r8kLXLxY+v+vHzbr4ufNtqnL9/1Uuf8NrsCt
        pXAoyZ0YqfbkWx3NHTZ7OE9ZRhdMP/RqHQE1p4N4Sa1nZKhTKasV6KhHDqSCt/dv
        Em89xWm2MVA7nyzQxVlHa9AkcBaemcXEiyT19XdpiXOP4Vhs+J1R5m8zQOxZlV1G
        tF9vsXmJqWZpOVPmZ8f35BCsYPvv4yMewnrtAC8PFEK/bOPeYcKN50bol22QYaZu
        LfpkHfNiFTnfMh8sl/ablPyNY7DUNiP5DRcMdIwmfGQxR5WEQoHL3yPJ42LkB5zs
        6jIm26DGNXfwura/mi105+ENH1CaROtRYwkiHb08U6qLXXJz80mWJkT90nr8Asj3
        5xN2cUppg74nG3YVav/38P48T56hG1NHbYF5uOCske19F6wi9maUoto/3vEr0rnX
        JUp2KODmKdvBI7co245lHBABWikk8VfejQSlCtDBXn644ZMtAdoxKNfR2WTFVEwJ
        iyd1Fzx0yujuiXDROLhISLQDRjVVAvawrAtLZWYK31bY7KlezPlQnl/D9Asxe85l
        8jO5+0LdJ6VyOs/Hd4w52alDW/MFySDZSfQHMTIc30hLBJ8OnCEIvluVQQ2UQvoW
        +no177N9L2Y+M9TcTA62ZyMXShHQGeh20rb4kK8f+iFX8NxtdHVSkxMEFSfDDyQ=
        -----END CERTIFICATE-----
      '';

    in
    {
      autoStart = true;
      privateNetwork = true;
      privateUsers = 131072;
      enableTun = true;
      hostAddress = hostAddress;
      localAddress = localAddress;

      # ZFS and secret mounts use :idmap in extraFlags
      extraFlags = [
        "--private-users-ownership=auto"
        "--system-call-filter=~@debug"
        "--bind=/mnt/data-pool/media:/media:idmap"
        "--bind-ro=/run/agenix-containers/arr:/run/secrets:idmap"
      ];

      config =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          systemd.tmpfiles.rules = [
            "d /run/pia 0700 root root -"
          ];

          services.openvpn.servers = {
            pia = {
              # TCP File from config generator because udp is buggy with my router
              config = ''
                client
                dev ${vpnInterface}
                proto ${vpnProto}
                remote ${vpnIP} ${vpnPort}
                resolv-retry infinite
                nobind
                persist-key
                persist-tun
                cipher aes-256-cbc
                auth sha256
                tls-client
                remote-cert-tls server

                verb 1
                reneg-sec 0

                <ca>
                ${caCert}
                </ca>

                disable-occ
              '';
              authUserPass = "/run/secrets/pia";
              autoStart = true;
              updateResolvConf = true;
              up =
                # bash
                ''
                  echo "Up script ran!"
                  mkdir -p /run/pia
                  chmod 0700 /run/pia
                  echo "PF_GATEWAY=$route_vpn_gateway" > /run/pia/pia-status.env
                  echo "PF_HOSTNAME=$common_name" >> /run/pia/pia-status.env
                '';
            };
          };

          systemd.services.openvpn-pia.serviceConfig = {
            ProtectHome = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            PrivateTmp = true;
            LockPersonality = true;
          };

          networking.firewall = {
            enable = true;

            # Enable strict reverse path filtering to prevent IP spoofing/leaks
            checkReversePath = "strict";
            interfaces.${containerInterface}.allowedTCPPorts = [
              8989
              9091
            ];

            extraCommands = ''
              # Dynamic inbound chain for active PIA forwarded torrent port only
              iptables -N pia-torrent-in 2>/dev/null || true
              iptables -A nixos-fw -i ${vpnInterface} -j pia-torrent-in

              # Allow Loopback (Required for internal processes)
              iptables -A OUTPUT -o lo -j ACCEPT

              # Allow LAN Access (WebUI, Local Discovery)
              iptables -A OUTPUT -d ${hostAddress} -j ACCEPT

              # Allow connection TO the VPN server (Bootstrapping the tunnel)
              iptables -A OUTPUT -o ${containerInterface} -p ${vpnProto} -d ${vpnIP} --dport ${toString vpnPort} -j ACCEPT

              # Allow all tunnel traffic
              iptables -A OUTPUT -o ${vpnInterface} -j ACCEPT

              #DROP EVERYTHING ELSE (Kill Switch)
              iptables -A OUTPUT -j DROP

              ip6tables -P INPUT DROP
              ip6tables -P OUTPUT DROP
              ip6tables -P FORWARD DROP
            '';

            # clean up rules when firewall is stopped
            extraStopCommands = ''
              iptables -D OUTPUT -j DROP 2> /dev/null || true
              iptables -F OUTPUT
              iptables -F pia-torrent-in 2> /dev/null || true
              iptables -X pia-torrent-in 2> /dev/null || true
            '';
          };

          systemd.timers.pia-port-forward = {
            description = "Refresh PIA Port Forwarding monthly";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "Mon *-*-1..7 03:00:00";
              Persistent = true;
              Unit = "pia-port-forward.service";
            };
          };

          systemd.services.pia-port-forward = {
            description = "PIA Port Forwarding";
            after = [ "openvpn-pia.service" ];
            bindsTo = [ "openvpn-pia.service" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              # PIA_USER
              # PIA_PASS
              EnvironmentFile = "/run/secrets/pia-env";
              Restart = "on-failure";
              RestartSec = "30s";
              NoNewPrivileges = true;
              ProtectSystem = "strict";
              ReadWritePaths = [ "/run/pia" ];
              ProtectHome = true;
              PrivateTmp = true;
              PrivateDevices = true;
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectControlGroups = true;
              CapabilityBoundingSet = "";
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              LockPersonality = true;
            };

            path = with pkgs; [
              curl
              jq
              coreutils
              gnugrep
            ];

            script =
              # bash
              ''
                STATUS_FILE="/run/pia/pia-status.env"
                TOKEN_FILE="/run/pia/pia-token.txt"
                PORT_FILE="/run/pia/pia-port.txt"
                CA_PATH="/run/pia/pia-ca.crt"

                if [ ! -f "$STATUS_FILE" ]; then
                  echo "VPN Status file not found. Is VPN up?"
                  exit 1
                fi
                source "$STATUS_FILE"

                echo "VPN Context Loaded -> Gateway: $PF_GATEWAY | Host: $PF_HOSTNAME"

                cat <<EOF > "$CA_PATH"
                ${caCert}
                EOF

                VPN_INTERFACE=${vpnInterface}

                # Check if token exists and is less than 23 hours old (82800 seconds)
                if [ -f "$TOKEN_FILE" ] && [ $(($(date +%s) - $(stat -c %Y "$TOKEN_FILE"))) -lt 82800 ]; then
                  echo "Using cached PIA Token."
                  PIA_TOKEN=$(cat "$TOKEN_FILE")
                else
                  echo "Token missing or expired. Requesting new one..."
                  RESPONSE=$(curl -s --location --request POST \
                    'https://www.privateinternetaccess.com/api/client/v2/token' \
                    --form "username=$PIA_USER" \
                    --form "password=$PIA_PASS")

                  NEW_TOKEN=$(echo "$RESPONSE" | jq -r '.token')

                  if [ "$NEW_TOKEN" != "null" ] && [ -n "$NEW_TOKEN" ]; then
                    echo "$NEW_TOKEN" > "$TOKEN_FILE"
                    PIA_TOKEN="$NEW_TOKEN"
                  else
                    echo "Failed to get token."
                    exit 1
                  fi
                fi

                echo "Requesting Signature..."
                SIG_RESPONSE=$(curl -s --get \
                  --connect-to "$PF_HOSTNAME::$PF_GATEWAY:" \
                  --cacert "$CA_PATH" \
                  --data-urlencode "token=$PIA_TOKEN" \
                  "https://$PF_HOSTNAME:19999/getSignature")


                SIGNATURE=$(echo "$SIG_RESPONSE" | jq -r '.signature')
                PAYLOAD=$(echo "$SIG_RESPONSE" | jq -r '.payload')

                PORT=$(echo "$PAYLOAD" | base64 -d | jq -r '.port')
                echo "Assigned Port: $PORT"
                echo "$PORT" > "$PORT_FILE"

                echo "Starting bind loop..."
                while true; do
                  BIND_RESPONSE=$(curl -s -m 5 \
                    --connect-to "$PF_HOSTNAME::$PF_GATEWAY:" \
                    --cacert "$CA_PATH" \
                    -G --data-urlencode "payload=$PAYLOAD" \
                    --data-urlencode "signature=$SIGNATURE" \
                    "https://$PF_HOSTNAME:19999/bindPort")

                  if [[ $(echo "$BIND_RESPONSE" | jq -r '.status') != "OK" ]]; then
                    echo "Bind failed: $BIND_RESPONSE"
                    exit 1
                  fi

                  echo "Port $PORT refreshed at $(date)"
                  sleep 900
                done
              '';
          };

          systemd.services.transmission-port-update = {
            description = "Update Transmission peer port from PIA forwarded port";
            after = [
              "firewall.service"
              "pia-port-forward.service"
              "transmission.service"
            ];
            requires = [
              "firewall.service"
              "pia-port-forward.service"
            ];

            serviceConfig = {
              Type = "oneshot";
              NoNewPrivileges = true;
              ProtectSystem = "full";
              ReadOnlyPaths = [ "/run/pia" ];
              ProtectHome = true;
              PrivateTmp = true;
              PrivateDevices = true;
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectControlGroups = true;
              CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              LockPersonality = true;
              ExecStart = pkgs.writeShellScript "transmission-port-update" ''
                if [ ! -f /run/pia/pia-port.txt ]; then
                  echo "PIA port file not found yet."
                  exit 0
                fi

                PORT=$(cat /run/pia/pia-port.txt)
                if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; then
                  echo "Invalid PIA forwarded port: $PORT"
                  exit 1
                fi

                # Permit only the active PIA forwarded torrent port on tun0
                iptables -w -N pia-torrent-in 2>/dev/null || true
                iptables -w -F pia-torrent-in
                iptables -w -A pia-torrent-in -i ${vpnInterface} -p tcp --dport "$PORT" -j nixos-fw-accept
                iptables -w -A pia-torrent-in -i ${vpnInterface} -p udp --dport "$PORT" -j nixos-fw-accept

                SESSION_ID=$(wget --server-response --output-document=/dev/null \
                  http://${localAddress}:9091/rpc 2>&1 \
                  | grep "^\s*X-Transmission-Session-Id:" \
                  | awk '{print $2}' | tr -d '\r' || true)
                echo "Setting Transmission peer port to $PORT"
                wget --post-data='{"method":"session-set","arguments":{"peer-port":'"$PORT"'}}' \
                  --header='Content-Type: application/json' \
                  --header="X-Transmission-Session-Id: $SESSION_ID" \
                  http://${localAddress}:9091/rpc -O -
              '';
            };

            path = with pkgs; [
              coreutils
              wget
              gawk
              gnugrep
              iptables
            ];
          };

          systemd.timers.transmission-port-update = {
            description = "Periodically sync Transmission port with PIA";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "2min";
              OnUnitActiveSec = "15m";
              Persistent = true;
            };
          };

          services.transmission = {
            enable = true;
            package = pkgs.transmission_4;
            group = "media";
            openRPCPort = false;
            settings = {
              pex-enabled = false;
              dht-enabled = false;
              lpd-enabled = false;
              download-dir = "/media/torrent";
              incomplete-dir = "${config.services.transmission.settings.download-dir}/.incomplete";
              #Override default settings
              rpc-bind-address = localAddress; # Bind only to container subnet veth IP
              rpc-whitelist = "192.168.100.14,192.168.100.15";
              rpc-whitelist-enabled = true;
              rpc-host-whitelist = "transmission.plamper.org,${localAddress}";
              rpc-host-whitelist-enabled = true;
              rpc-url = "/";
              speed-limit-down = 7000;
              speed-limit-down-enabled = true;
              speed-limit-up = 1000;
              speed-limit-up-enabled = true;

              # Limit Speed between 17:00 and 23:00
              alt-speed-up = 100;
              alt-speed-down = 100;
              alt-speed-time-enabled = true;
              alt-speed-time-begin = 1020;
              alt-speed-time-end = 1380;
              seed-queue-enabled = true;
              seed-queue-size = 3;
              ratio-limit = 10;
              ratio-limit-enabled = true;

              # Disable UPnP
              port-forwarding-enabled = false;
            };
          };

          users.groups.media.gid = 555;

          # Transmission Container Fix
          systemd.services.transmission.serviceConfig = {
            RootDirectoryStartOnly = lib.mkForce false;
            RootDirectory = lib.mkForce "";
          };

          services.sonarr = {
            enable = true;
            openFirewall = false;
            group = "media";
          };

          systemd.services.sonarr.serviceConfig = {
            # Nested PrivateUsers + ProtectProc="invisible" fails 217/USER under nspawn privateUsers
            PrivateUsers = lib.mkForce false;
            ProtectSystem = "strict";
            ReadWritePaths = [
              "/var/lib/sonarr"
              "/media"
            ];
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
          };

          # # needs to be configured when finally deployed
          # services.prometheus.exporters.exportarr-sonarr = {
          #   enable = false;
          #   port = 9003;
          # };
          system.stateVersion = "24.05";

          networking = {
            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            useHostResolvConf = lib.mkForce false;
          };

          networking.resolvconf.enable = true;

          time.timeZone = lib.mkDefault "Europe/Berlin";

        };
    };
}
