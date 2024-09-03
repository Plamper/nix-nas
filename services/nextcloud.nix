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
    config = { config, pkgs, lib, ... }: {

      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud29;
        hostName = "test-nextcloud.bodenlos-schlem.men";
        https = true;
        config.adminpassFile = "${pkgs.writeText "adminpass" "test123"}"; # DON'T DO THIS IN PRODUCTION - the password file will be world-readable in the Nix Store!
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

    };
  };
}
