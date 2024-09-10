{ config, pkgs, lib, ... }:
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
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
    home = "/mnt/data-pool/nextcloud";
    # Recognize has to be installed from AppStore as models are unable to be downloaded
    appstoreEnable = true;
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) contacts calendar tasks memories previewgenerator notes;
    };
    extraAppsEnable = true;
    maxUploadSize = "10G";
    settings = {
      "memories.exiftool" = "${lib.getExe pkgs.exiftool}";
      "memories.vod.ffmpeg" = "${pkgs.jellyfin-ffmpeg}/bin/ffmpeg";
      "memories.vod.ffprobe" = "${pkgs.jellyfin-ffmpeg}/bin/ffprobe";
      default_phone_region = "DE";
      maintenance_window_start = 6;
    };
  };

  environment.systemPackages = [ pkgs.nodejs_20 pkgs.jellyfin-ffmpeg ];

  systemd.services.nextcloud-cron = {
    path = [ pkgs.perl ];
  };

  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  # Add groups to nextcloud so it is able to access drives
  # Render and Video may not be nescessary
  users.users = { nextcloud.extraGroups = [ "pictures" "felix" "render" "video" ]; };

  # Patch ffmpeg and intel vaapi driver for qsv
  nixpkgs.overlays = with pkgs; [
    # https://github.com/NixOS/nixpkgs/issues/303074
    # May no longer be necessary with next nixos version
    (final: prev: {
      jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
        ffmpeg_6-full = prev.ffmpeg_6-full.override {
          withMfx = false;
          withVpl = true;
        };
      };
    })
    (final: prev: {
      intel-vaapi-driver = prev.intel-vaapi-driver.override { enableHybridCodec = true; };
    })
  ];

  hardware.opengl = {
    # hardware.opengl in 24.05
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver # previously vaapiIntel
      vaapiVdpau
      onevpl-intel-gpu # QSV on 11th gen or newer
      # intel-media-sdk # QSV up to 11th gen
    ];
  };


  # Allow hardware Transcoding
  systemd.services."phpfpm-nextcloud".serviceConfig = {
    DeviceAllow = [ "/dev/dri/renderD128" ];
    # Device Allow does not work for some reason
    PrivateDevices = lib.mkForce false;
    SupplementaryGroups = [ "render" "video" ];
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
  };
}
