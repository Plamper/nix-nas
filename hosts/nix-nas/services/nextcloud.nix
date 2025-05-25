{
  config,
  pkgs,
  lib,
  agenix,
  ...
}:
{

  containers.nextcloud = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";

    bindMounts = {
      "/Felix" = {
        hostPath = "/mnt/data-pool/Felix";
        isReadOnly = false;
      };
    };
    bindMounts = {
      "/Photos" = {
        hostPath = "/mnt/data-pool/Pictures/";
        isReadOnly = false;
      };
    };
    bindMounts = {
      "/Nextcloud" = {
        hostPath = "/mnt/data-pool/nextcloud";
        isReadOnly = false;
      };
    };
    bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true;
    bindMounts."/dev/dri".isReadOnly = false;

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

        imports = [ agenix.nixosModules.default ];

        age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        age.secrets = {
          "nextcloud" = {
          # Find better solution
            file = ../../../secrets/nextcloud.age;
            owner = "nextcloud";
            group = "nextcloud";
          };
          "nc-pg-pass" = {
            file = ../../../secrets/nc-pg-pass.age;
            owner = "nextcloud";
            group = "nextcloud";
          };
        };

        services.nextcloud = {
          enable = true;
          package = pkgs.nextcloud31;
          hostName = "nextcloud.bodenlos-schlem.men";
          https = true;
          configureRedis = true;
          config = {
            adminuser = "admin";
            adminpassFile = config.age.secrets."nextcloud".path;

            # Nextcloud PostegreSQL database configuration, recommended over using SQLite
            dbtype = "pgsql";
            dbuser = "nextcloud";
            dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
            dbname = "nextcloud";
            dbpassFile = config.age.secrets."nc-pg-pass".path;
          };
          home = "/Nextcloud";
          # Recognize has to be installed from AppStore as models are unable to be downloaded
          appstoreEnable = true;
          extraApps = {
            inherit (config.services.nextcloud.package.packages.apps)
              contacts
              calendar
              tasks
              previewgenerator
              notes
              ;
          };
          extraAppsEnable = true;
          maxUploadSize = "10G";
          settings = {
            "memories.exiftool" = "${lib.getExe pkgs.exiftool}";
            "memories.vod.ffmpeg" = "${pkgs.jellyfin-ffmpeg}/bin/ffmpeg";
            "memories.vod.ffprobe" = "${pkgs.jellyfin-ffmpeg}/bin/ffprobe";
            default_phone_region = "DE";
            maintenance_window_start = 6;
            trusted_proxies = [ "192.168.100.10" ];
            # Enable PDF and HEIC
            enabledPreviewProviders = [
              "OC\\Preview\\BMP"
              "OC\\Preview\\GIF"
              "OC\\Preview\\JPEG"
              "OC\\Preview\\Krita"
              "OC\\Preview\\MarkDown"
              "OC\\Preview\\MP3"
              "OC\\Preview\\OpenDocument"
              "OC\\Preview\\PNG"
              "OC\\Preview\\TXT"
              "OC\\Preview\\XBitmap"
              "OC\\Preview\\HEIC"
              "OC\\Preview\\PDF"
            ];
          };
        };

        environment.systemPackages = [
          pkgs.nodejs_20
          pkgs.jellyfin-ffmpeg
        ];

        systemd.services.nextcloud-cron = {
          path = [ pkgs.perl ];
        };

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
          ];
        };
        users.groups = {
          pictures.gid = 3000;
          felix.gid = 4000;
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
        ];

        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            intel-vaapi-driver # previously vaapiIntel
            vaapiVdpau
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
          ];
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
               superuser_map      postgres  postgres
               superuser_map      root      nextcloud
               # Let other names login as themselves
               superuser_map      /^(.*)$   \1
          '';
        };

        services.prometheus.exporters.nextcloud = {
          enable = true;
          # Set user and group to nextcloud so agenix file is readable
          user = "nextcloud";
          group = "nextcloud";

          url = "http://${config.services.nextcloud.hostName}";
          username = "admin";
          passwordFile = config.age.secrets."nextcloud".path;
          port = 9003;
          openFirewall = true;
        };

        system.stateVersion = "24.05";

        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [ 80 ];
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
