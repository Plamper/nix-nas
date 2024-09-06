{ agenix, ... }:
{

  containers.nextcloud = {
    autoStart = true;
    privateNetwork = true;
    # forwardPorts = [{
    #   hostPort = 80;
    #   containerPort = 8080;
    # }];
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    # hostAddress6 = "fc00::1";
    # localAddress6 = "fc00::2";

    bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true;

    config = { config, pkgs, lib, ... }: {

      imports = [ agenix.nixosModules.default ];

      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; # isn't set automatically for some reason

      # import the secret
      age.secrets."nextcloud" = {
        file = ../secrets/nextcloud.age;
        owner = "nextcloud";
        group = "nextcloud";
      };

      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud29;
        hostName = "test-nextcloud.bodenlos-schlem.men";
        https = false;
        configureRedis = true;
        config.adminuser = "admin";
        config.adminpassFile = config.age.secrets."nextcloud".path;
      };

      services.prometheus.exporters.nextcloud = {
        enable = true;
        # Set user and group to nextcloud so agenix file is readable
        user = "nextcloud";
        group = "nextcloud";

        url = "http://127.0.0.1:80";
        username = "admin";
        passwordFile = config.age.secrets."nextcloud".path;
        port = 9000;
      };

      system.stateVersion = "24.05";

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 80 9000 ];
        };
        # Use systemd-resolved inside the container
        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        useHostResolvConf = lib.mkForce false;
      };

      services.resolved.enable = true;

    };
  };
}
