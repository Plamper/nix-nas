{ pkgs, ... }:
{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Prevent accidental import on other host
  networking.hostId = "74ba3a16";

  boot.zfs.extraPools = [ "data-pool" ];

  services.zfs.zed.settings = {
    ZED_DEBUG_LOG = "/tmp/zed.debug.log";
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
    ZED_EMAIL_OPTS = "@ADDRESS@";

    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;

    ZED_USE_ENCLOSURE_LEDS = true;
    ZED_SCRUB_AFTER_RESILVER = true;
  };
  # this option does not work; will return error
  services.zfs.zed.enableMail = false;

  environment.systemPackages = [ pkgs.smartmontools ];

  services.smartd = {
    enable = true;
    notifications.mail.enable = true;
  };

  services.prometheus.exporters.zfs = {
    enable = true;
    port = 9006;
  };
}
