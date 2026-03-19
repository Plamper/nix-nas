{ pkgs, ... }:
{

  # GUC for hw dec
  boot.kernelParams = [ "i915.enable_guc=3" "i915.enable_fbc=1" ];

  containers.jellyfin = {
    autoStart = true;
    privateNetwork = true;
    # forwardPorts = [{
    #   hostPort = 8096;
    # }];
    hostAddress = "192.168.100.12";
    localAddress = "192.168.100.13";
    # hostAddress6 = "fc00::1";
    # localAddress6 = "fc00::2";

    bindMounts = {
      "/Music" = {
        hostPath = "/mnt/data-pool/media/Music";
        isReadOnly = false;
      };
    };
    bindMounts = {
      "/Video" = {
        hostPath = "/mnt/data-pool/media/Video";
        isReadOnly = false;
      };
    };
    bindMounts."/dev/dri".isReadOnly = false;

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


    config = { config, pkgs, lib, ... }: {

      # intro skipper fix
      nixpkgs.overlays = with pkgs; [
        # https://github.com/NixOS/nixpkgs/issues/303074
        # May no longer be necessary with next nixos version
        (final: prev: {
          jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
            ffmpeg_7-full = prev.ffmpeg_7-full.override {
              withMfx = false;
              withVpl = true;
            };
          };
        })
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
      environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; };


      users.groups.media.gid = 555;

      services.jellyfin = {
        enable = true;
        openFirewall = true;
        group = "media";
      };
      environment.systemPackages = [
        pkgs.jellyfin
        pkgs.jellyfin-web
        pkgs.jellyfin-ffmpeg
        pkgs.libva-utils
      ];

      users.users.jellyfin.extraGroups = [ "render" "video" ];

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
