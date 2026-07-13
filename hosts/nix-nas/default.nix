{
  inputs,
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}:
{

  imports = [
    # (modulesPath + "/virtualisation/virtualbox-image.nix")
    ./hardware-configuration.nix
    ../../secrets
    inputs.dyn-channels.nixosModules.default

    # Shared modules
    ../shared

    # Services
    ./services/zfs.nix
    ./services/openssh.nix
    ./services/nextcloud.nix
    ./services/jellyfin.nix
    ./services/arr.nix
    # ./services/immich.nix
    # ./services/monitoring.nix
    ./services/podman-containers.nix
    ./services/reverse-proxy.nix
    ./services/users.nix
    ./services/samba.nix
    ./services/email.nix
    ./services/blocky.nix
    ./services/postgres.nix
    ./services/auth.nix
    ./services/forgejo.nix
  ];
  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
    hostPlatform = "x86_64-linux";
  };

  networking.hostName = "nix-nas";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  programs.nix-ld.enable = true;

  networking = {

    firewall.enable = true;

    # nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    # enableIPv6 = false;

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp2s0";
      # Lazy IPv6 connectivity for the containe
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  networking.wireguard.enable = true;
  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the client's end of the tunnel interface.
      ips = [ "10.20.0.2/24" ];
      # listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)
      mtu = 1360;

      privateKeyFile = config.age.secrets.nix-nas-private-key.path;

      peers = [
        # For a client configuration, one peer entry for the server will suffice.

        {
          # Public key of the server (not a file path).
          publicKey = "45qWd/gUOc2xVUWK0jtrp3FD81qdwtVGDVRARcM3oQs=";
          # Or forward only particular subnets
          allowedIPs = [ "10.20.0.0/24" ];

          # Set this to the server IP and port.
          endpoint = "150.230.147.99:51820"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

          # Send keepalives every 25 seconds. Important to keep NAT tables alive.
          persistentKeepalive = 25;
        }
      ];
    };
  };
  networking.firewall.trustedInterfaces = [ "wg0" ];

  # Discord Bot
  services.dynamic-channels-bot = {
    enable = true;
    tokenFile = config.age.secrets.dyn-channel-token.path;
  };
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
