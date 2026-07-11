{
  config,
  agenix,
  pkgs,
  lib,
  ...
}:
{

  services.nginx.virtualHosts."transmission.bodenlos-schlem.men" = {
    enableACME = true;
    acmeRoot = null;
    forceSSL = true;
    enableAuthelia = true;

    locations."/" = {
      proxyPass = "http://192.168.100.15:9091";
      extraConfig = ''
        proxy_pass_header X-Transmission-Session-Id;
      '';
    };
  };
  services.nginx.virtualHosts."sonarr.bodenlos-schlem.men" = {
    enableACME = true;
    acmeRoot = null;
    forceSSL = true;
    enableAuthelia = true;

    locations."/" = {
      proxyPass = "http://192.168.100.15:8989/";
    };
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
      enableTun = true;
      hostAddress = hostAddress;
      localAddress = localAddress;

      bindMounts = {
        "/media" = {
          hostPath = "/mnt/data-pool/media/";
          isReadOnly = false;
        };
      };
      bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true;

      config =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          imports = [
            agenix.nixosModules.default
          ];

          age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          age.secrets = {
            "pia".file = ../../../secrets/pia.age;
            "pia-env".file = ../../../secrets/pia-env.age;
          };

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
              authUserPass = config.age.secrets."pia".path;
              autoStart = true;
              updateResolvConf = true;
              up =
                # bash
                ''
                  echo "Up script ran!"
                  echo "PF_GATEWAY=$route_vpn_gateway" > /tmp/pia-status.env
                  echo "PF_HOSTNAME=$common_name" >> /tmp/pia-status.env
                '';
            };
          };

          networking.firewall = {
            enable = true;
            allowedTCPPorts = [
              22
            ];

            # Enable strict reverse path filtering to prevent IP spoofing/leaks
            checkReversePath = "strict";
            trustedInterfaces = [ "${vpnInterface}" ];

            extraCommands = ''
              # Allow Loopback (Required for internal processes)
              iptables -A OUTPUT -o lo -j ACCEPT

              # Allow LAN Access (SSH, WebUI, Local Discovery)
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
              EnvironmentFile = config.age.secrets."pia-env".path;
              Restart = "on-failure";
              RestartSec = "30s";
            };

            path = with pkgs; [
              curl
              jq
              iproute2
              coreutils
              gnugrep
              iptables
            ];

            script =
              # bash
              ''
                STATUS_FILE="/tmp/pia-status.env"
                TOKEN_FILE="/tmp/pia-token.txt"
                PORT_FILE="/tmp/pia-port.txt"
                CA_PATH="/tmp/pia-ca.crt"

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
              "pia-port-forward.service"
              "transmission.service"
            ];
            requires = [ "pia-port-forward.service" ];

            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "transmission-port-update" ''
                PORT=$(cat /tmp/pia-port.txt)
                SESSION_ID=$(wget --server-response --output-document=/dev/null \
                  http://127.0.0.1:9091/rpc 2>&1 \
                  | grep "^\s*X-Transmission-Session-Id:" \
                  | awk '{print $2}')
                echo "Setting Transmission peer port to $PORT"
                wget --post-data='{"method":"session-set","arguments":{"peer-port":'"$PORT"'}}' \
                  --header='Content-Type: application/json' \
                  --header="X-Transmission-Session-Id: $SESSION_ID" \
                  http://127.0.0.1:9091/rpc -O -
              '';
            };

            path = with pkgs; [
              wget
              gawk
              gnugrep
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
            openRPCPort = true;
            settings = {
              pex-enabled = false;
              dht-enabled = false;
              lpd-enabled = false;
              download-dir = "/media/torrent";
              incomplete-dir = "${config.services.transmission.settings.download-dir}/.incomplete";
              #Override default settings
              rpc-bind-address = "0.0.0.0"; # Bind to own IP
              rpc-whitelist = "127.0.0.1,192.168.100.*,transmission.bodenlos-schlem.men,auth.bodenlos-schlem.men";
              rpc_host_whitelist_enabled = false;
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

          # Sonarr is dotnet 6 app which is marked is insecure
          nixpkgs.config.permittedInsecurePackages = [
            "aspnetcore-runtime-wrapped-6.0.36"
            "aspnetcore-runtime-6.0.36"
            "dotnet-sdk-wrapped-6.0.428"
            "dotnet-sdk-6.0.428"
          ];

          services.sonarr = {
            enable = true;
            openFirewall = true;
            group = "media";
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
