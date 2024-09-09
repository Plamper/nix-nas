{ pkgs, ...}:
{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Prevent accidental import on other host
  networking.hostId = "74ba3a16";

  boot.zfs.extraPools = [ "data-pool" ];

  services.smartd.enable = true;
}