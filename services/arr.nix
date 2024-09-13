{ config, pia-nix, agenix, pkgs, lib, ... }:
{

  imports = [ pia-nix.nixosModules.default ];

  services.pia-wg = {
    enable = true;
    username = "p8566938";
    passwordFile = config.age.secrets."vpn".path;
    region = "swiss";
    # services = [ "container@arr" ];
    nat = [ 9091 8989 ];
    portForwarding.enable = true;
    portForwarding.transmission = {
      enable = true;
    };
  };

  systemd.services."container@arr" = {
    after = [ "pia-wg.service" ];
    # requires = [ "pia-wg.service" ];
    # Wait for namespace to exist
    serviceConfig.ExecStartPre = "${pkgs.bash}/bin/bash -c 'until [ -f /run/netns/pia ]; do sleep 1; done'";
  };

  # I dont know why this is nescessary but service fails otherwise
  systemd.services."pia-wg-pf" = {
    after = lib.mkForce [ "pia-wg.service" "container@arr.service" ];
    bindsTo = lib.mkForce [ ];
    serviceConfig.ExecStartPre = "${pkgs.bash}/bin/bash -c 'while ! ${pkgs.libressl.nc}/bin/nc -z 127.0.0.1 9091; do sleep 1; done'";
  };

  containers.arr = {
    autoStart = true;
    privateNetwork = true;

    bindMounts = {
      "/media" = {
        hostPath = "/mnt/data-pool/media/";
        isReadOnly = false;
      };
    };
    extraFlags = [ "--network-namespace-path=/run/netns/pia" ];


    config = { config, pkgs, lib, ... }: {

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
          rpc-bind-address = "0.0.0.0"; #Bind to own IP
          rpc-whitelist = "127.0.0.1,192.168.1.*";
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
        # openFirewall = true;
        group = "media";
      };

      # # needs to be configured when finally deployed 
      # services.prometheus.exporters.exportarr-sonarr = {
      #   enable = false;
      #   port = 9003;
      # };
      system.stateVersion = "24.05";

      networking = {
        # Probably safe as only the torrent port is public
        firewall.enable = false;
        # Use systemd-resolved inside the container
        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        useHostResolvConf = lib.mkForce false;
      };

      services.resolved.enable = true;

      time.timeZone = lib.mkDefault "Europe/Berlin";

    };
  };
  # networking.firewall.allowedTCPPorts = [ 8989 9091 ];
}
