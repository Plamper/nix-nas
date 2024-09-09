{ config, pia-nix, agenix, pkgs, ... }:
{


  imports = [
    pia-nix.nixosModules.default
    agenix.nixosModules.default
  ];

  users.groups.media.gid = 555;

  services.pia-wg = {
    enable = true;
    username = "p8566938";
    passwordFile = config.age.secrets."vpn".path;
    region = "swiss";
    services = [ "transmission" "sonarr" ];
    nat = [ 9091 8989 ];
    portForwarding.enable = true;
    portForwarding.transmission = {
      enable = true;
      username = "transmission";
      password = "123";
    };
  };

  # environment.systemPackages = [ pkgs.flood-for-transmission ];

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    settings = {
      download-dir = "/mnt/data-pool/media/torrent";
      #Override default settings
      rpc-bind-address = "0.0.0.0"; #Bind to own IP
      rpc-whitelist = "127.0.0.1,192.168.1.*"; #Whitelist your remote machine (10.0.0.1 in this example)
    };
  };


  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  # needs to be configured when finally deployed 
  services.prometheus.exporters.exportarr-sonarr = {
    enable = false;
    port = 9003;
  };
}
