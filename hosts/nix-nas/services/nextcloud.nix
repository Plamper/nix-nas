{
  config,
  pkgs,
  lib,
  ...
}:
{

  users.groups.nextcloud-secrets.gid = 4500;

  age.secrets = {
    "nextcloud" = {
      file = ../../../secrets/nextcloud.age;
      path = "/run/agenix-containers/nextcloud/nextcloud";
      symlink = false;
      owner = "root";
      group = "nextcloud-secrets";
      mode = "0440";
    };
    "nc-pg-pass" = {
      file = ../../../secrets/nc-pg-pass.age;
      path = "/run/agenix-containers/nextcloud/nc-pg-pass";
      symlink = false;
      owner = "root";
      group = "nextcloud-secrets";
      mode = "0440";
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/data-pool/Backups/nextcloud 0700 postgres postgres -"
    "d /run/agenix-containers/nextcloud 0750 root nextcloud-secrets -"
  ];

  # Grant GPU render/card ACL strictly to container's mapped container-dri GID (196608 + 4501)
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", RUN+="${pkgs.acl}/bin/setfacl -m g:201109:rw /dev/dri/%k"
    SUBSYSTEM=="drm", KERNEL=="card*", RUN+="${pkgs.acl}/bin/setfacl -m g:201109:rw /dev/dri/%k"
  '';

  systemd.services."container@nextcloud" = {
    unitConfig.RequiresMountsFor = [
      "/mnt/data-pool/nextcloud"
      "/mnt/data-pool/Backups/nextcloud"
      "/run/agenix-containers/nextcloud"
    ];
    serviceConfig = {
      ProtectHome = true;
    };
  };

  containers.nextcloud = {
    autoStart = true;
    privateNetwork = true;
    privateUsers = 196608;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";

    # devtmpfs does not support :idmap; ZFS and secret mounts use :idmap in extraFlags
    bindMounts."/dev/dri".isReadOnly = false;

    extraFlags = [
      "--private-users-ownership=auto"
      "--system-call-filter=~@debug"
      "--bind=/mnt/data-pool/nextcloud:/Nextcloud:idmap"
      "--bind=/mnt/data-pool/Backups/nextcloud:/mnt/data-pool/Backups/nextcloud:idmap"
      "--bind-ro=/run/agenix-containers/nextcloud:/run/secrets:idmap"
    ];

    allowedDevices = [
      {
        modifier = "rw";
        node = "/dev/dri/card0";
      }
      {
        modifier = "rw";
        node = "/dev/dri/renderD128";
      }
    ];

    config =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {

        imports = [
          # Module which allows turning on private ip
          ./onlyoffice.nix
        ];

        services.nginx.virtualHosts = {
          "cloud.plamper.org" = {
            addSSL = false; # Disables SSL for this host
            forceSSL = false;
            enableACME = false;
          };

        };

        services.nextcloud = {
          enable = true;
          package = pkgs.nextcloud35;
          hostName = "cloud.plamper.org";
          https = false;
          configureRedis = true;
          phpOptions."opcache.interned_strings_buffer" = "32";
          config = {
            adminuser = "admin";
            adminpassFile = "/run/secrets/nextcloud";

            # Nextcloud PostegreSQL database configuration, recommended over using SQLite
            dbtype = "pgsql";
            dbuser = "nextcloud";
            dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
            dbname = "nextcloud";
            dbpassFile = "/run/secrets/nc-pg-pass";
          };
          home = "/Nextcloud";
          # Recognize has to be installed from AppStore as models are unable to be downloaded
          appstoreEnable = true;
          extraApps = {
            inherit (config.services.nextcloud.package.packages.apps)
              contacts
              calendar
              tasks
              # previewgenerator
              notes
              # needs to be configured in web-ui
              user_oidc
              mail
              ;
          };
          extraAppsEnable = true;
          maxUploadSize = "10G";
          settings = {
            mail_smtpsecure = "ssl";
            mail_smtpport = 465;
            mail_smtpname = "noreply@plamper.org";
            mail_smtphost = "mail.plamper.org";
            mail_smtpauth = true;
            mail_from_address = "noreply";
            mail_domain = "plamper.org";
            "memories.exiftool" = "${lib.getExe pkgs.exiftool}";
            # "memories.exiftool_no_local" = false;
            "memories.vod.ffmpeg" = "${pkgs.jellyfin-ffmpeg}/bin/ffmpeg";
            "memories.vod.ffprobe" = "${pkgs.jellyfin-ffmpeg}/bin/ffprobe";
            "memories.timeline.default_path" = "/Photos";
            preview_ffmpeg_path = "${pkgs.jellyfin-ffmpeg}/bin/ffmpeg";
            default_phone_region = "DE";
            maintenance_window_start = 6;
            allow_user_to_change_display_name = false;
            lost_password_link = "disabled";
            trusted_proxies = [
              "192.168.100.10"
              "10.20.0.1"
              "150.230.147.99"
            ];
            files.chunked_upload.max_size = 99000000;
            overwriteprotocol = "https";
            # Enable PDF and HEIC
            enabledPreviewProviders = [
              "OC\\Preview\\TIFF"
              "OC\\Preview\\Krita"
              "OC\\Preview\\MarkDown"
              "OC\\Preview\\MP3"
              "OC\\Preview\\OpenDocument"
              "OC\\Preview\\TXT"
              "OC\\Preview\\HEIC"
              "OC\\Preview\\PDF"
              "OC\\Preview\\Image"
              "OC\\Preview\\Movie"
            ];
          };
        };

        environment.systemPackages = [
          pkgs.nodejs_22
          pkgs.jellyfin-ffmpeg
          pkgs.ghostscript
          pkgs.exiftool
          pkgs.tmux
        ];

        systemd.services.nextcloud-cron = {
          path = [
            pkgs.exiftool
            pkgs.perl
          ];
          serviceConfig = {
            NoNewPrivileges = true;
            ProtectSystem = "full";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
            CapabilityBoundingSet = "";
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "~@privileged"
            ];
          };
        };

        systemd.services.phpfpm-nextcloud.path = [
          pkgs.exiftool
          pkgs.perl
        ];

        systemd.services."nextcloud-setup" = {
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
        };

        # Add groups to nextcloud so it is able to access drives
        # Render and Video may not be necessary
        users.users = {
          nextcloud.extraGroups = [
            "pictures"
            "felix"
            "render"
            "video"
            "nextcloud-secrets"
            "container-dri"
          ];
        };
        users.groups = {
          pictures.gid = 3000;
          felix.gid = 4000;
          nextcloud-secrets.gid = 4500;
          container-dri.gid = 4501;
        };

        # Patch ffmpeg and intel vaapi driver for qsv
        nixpkgs.overlays = with pkgs; [
          # https://github.com/NixOS/nixpkgs/issues/303074
          # May no longer be necessary with next nixos version
          (final: prev: {
            jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
              ffmpeg_7-full = prev.ffmpeg_7-full.override {
                withMfx = false;
                withVpl = true;
              };
            };
          })
          (final: prev: {
            intel-vaapi-driver = prev.intel-vaapi-driver.override { enableHybridCodec = true; };
          })
          # (final: prev: {
          #   exiftool = prev.exiftool.overrideAttrs (
          #     f: p: {
          #       version = "13.44";
          #       src = pkgs.fetchurl {
          #         url = "https://github.com/exiftool/exiftool/archive/refs/tags/13.44.tar.gz";
          #         hash = "sha256-uiPgu1Cv+BWG8D3GBXvGDokp2o1hW1TLn6+T0EDMBRY=";
          #       };
          #     }
          #   );
          # })
        ];

        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            intel-vaapi-driver # previously vaapiIntel
            libva-vdpau-driver
            vpl-gpu-rt # QSV on 11th gen or newer
            # intel-media-sdk # QSV up to 11th gen
          ];
        };

        # Allow hardware Transcoding
        systemd.services."phpfpm-nextcloud".serviceConfig = {
          DeviceAllow = [ "/dev/dri/renderD128" ];
          # Device Allow does not work for some reason
          PrivateDevices = lib.mkForce false;
          SupplementaryGroups = [
            "render"
            "video"
            "container-dri"
          ];
          NoNewPrivileges = true;
          # Master process starts as root to chown the socket and drop worker privileges
          CapabilityBoundingSet = [
            "CAP_CHOWN"
            "CAP_SETUID"
            "CAP_SETGID"
            "CAP_DAC_OVERRIDE"
          ];
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
        };

        # Setup Postgres
        services.postgresql = {
          enable = true;

          # Ensure the database, user, and permissions always exist
          ensureDatabases = [ "nextcloud" ];
          ensureUsers = [
            {
              name = "nextcloud";
              ensureDBOwnership = true;
            }
          ];

          # Copied from wiki to fix postgres login
          authentication = pkgs.lib.mkOverride 10 ''
            #type database  DBuser  auth-method optional_ident_map
            local sameuser  all     peer        map=superuser_map
          '';
          identMap = ''
            # ArbitraryMapName systemUser DBUser
               superuser_map      root      postgres
               # Let other names login as themselves
               superuser_map      /^(.*)$   \1
          '';
        };

        services.postgresqlBackup = {
          enable = true;
          databases = [ "nextcloud" ];
          location = "/mnt/data-pool/Backups/nextcloud";
          startAt = "*-*-* 01:15:00";
        };

        systemd.tmpfiles.rules = [
          "d /mnt/data-pool/Backups/nextcloud 0700 postgres postgres -"
        ];

        services.prometheus.exporters.nextcloud = {
          enable = true;
          # Set user and group to nextcloud so mounted secret is readable
          user = "nextcloud";
          group = "nextcloud";

          url = "http://${config.services.nextcloud.hostName}";
          username = "admin";
          passwordFile = "/run/secrets/nextcloud";
          port = 9003;
          openFirewall = true;
        };

        systemd.services.prometheus-nextcloud-exporter.serviceConfig.SupplementaryGroups = [
          "nextcloud-secrets"
        ];

        system.stateVersion = "24.05";

        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [
              80
              443
            ];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };

        services.resolved.enable = true;

        time.timeZone = lib.mkDefault "Europe/Berlin";

      };
  };
}
