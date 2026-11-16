{ pkgs, inputs, ... }:
{

  # GUC for hw dec
  boot.kernelParams = [
    "i915.enable_guc=3"
    "i915.enable_fbc=1"
  ];

  # Grant GPU render/card ACL strictly to Jellyfin container's mapped media GID (262144 + 555)
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", RUN+="${pkgs.acl}/bin/setfacl -m g:262699:rw /dev/dri/%k"
    SUBSYSTEM=="drm", KERNEL=="card*", RUN+="${pkgs.acl}/bin/setfacl -m g:262699:rw /dev/dri/%k"
  '';

  systemd.services."container@jellyfin" = {
    unitConfig.RequiresMountsFor = [
      "/mnt/data-pool/media/Music"
      "/mnt/data-pool/media/Video"
    ];
    serviceConfig = {
      ProtectHome = true;
    };
  };

  containers.jellyfin = {
    nixpkgs = inputs.nixpkgs-unstable;
    autoStart = true;
    privateNetwork = true;
    privateUsers = 262144;
    # forwardPorts = [{
    #   hostPort = 8096;
    # }];
    hostAddress = "192.168.100.12";
    localAddress = "192.168.100.13";
    # hostAddress6 = "fc00::1";
    # localAddress6 = "fc00::2";

    # devtmpfs does not support :idmap; ZFS media mounts use :idmap in extraFlags
    bindMounts."/dev/dri".isReadOnly = false;

    extraFlags = [
      "--private-users-ownership=auto"
      "--system-call-filter=~@debug"
      "--bind=/mnt/data-pool/media/Music:/Music:idmap"
      "--bind=/mnt/data-pool/media/Video:/Video:idmap"
    ];

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

        nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

        nixpkgs.overlays = [
          (final: prev: {
            intel-vaapi-driver = prev.intel-vaapi-driver.override { enableHybridCodec = true; };
          })
        ];

        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            intel-vaapi-driver # previously vaapiIntel
            libva-vdpau-driver
            intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
            vpl-gpu-rt # QSV on 11th gen or newer
            # intel-media-sdk # QSV up to 11th gen
          ];
        };
        environment.sessionVariables = {
          LIBVA_DRIVER_NAME = "iHD";
        };

        users.groups.media.gid = 555;

        services.jellyfin = {
          enable = true;
          openFirewall = true;
          group = "media";
        };
        # Nested PrivateUsers + ProtectProc="invisible" fails 217/USER under nspawn privateUsers
        systemd.services.jellyfin.serviceConfig.PrivateUsers = lib.mkForce false;
        environment.systemPackages = [
          pkgs.jellyfin
          pkgs.jellyfin-web
          pkgs.jellyfin-ffmpeg
          pkgs.libva-utils
        ];

        users.users.jellyfin.extraGroups = [
          "render"
          "video"
        ];

        system.stateVersion = "24.05";

        networking = {
          firewall = {
            enable = true;
            # allowedTCPPorts = [ 8096 ];
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
