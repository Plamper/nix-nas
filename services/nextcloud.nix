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
    appstoreEnable = true;
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) contacts calendar tasks memories previewgenerator notes;
    };
    extraAppsEnable = true;
    maxUploadSize = "10G";
    settings = {
      "memories.exiftool" = "${lib.getExe pkgs.exiftool}";
      "memories.vod.ffmpeg" = "${lib.getExe pkgs.ffmpeg-headless}";
      "memories.vod.ffprobe" = "${pkgs.ffmpeg-headless}/bin/ffprobe";
      default_phone_region = "DE";
      maintenance_window_start = 6;
    };
  };

  environment.systemPackages = [ pkgs.nodejs_20 ];

  systemd.services.nextcloud-cron = {
    path = [ pkgs.perl ];
  };

  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };


  users.users = { nextcloud.extraGroups = [ "pictures" "felix" "render" " video" ]; };


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
