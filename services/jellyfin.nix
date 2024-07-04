{

  containers.jellyfin = {
    autoStart = true;
    privateNetwork = true;
    forwardPorts = [{
      hostPort = 8096;
    }];
    hostAddress = "192.168.100.12";
    localAddress = "192.168.100.13";
    # hostAddress6 = "fc00::1";
    # localAddress6 = "fc00::2";
    config = { config, pkgs, lib, ... }: {

      services.jellyfin.enable = true;
      environment.systemPackages = [
        pkgs.jellyfin
        pkgs.jellyfin-web
        pkgs.jellyfin-ffmpeg
      ];


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
