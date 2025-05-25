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

    # Shared modules
    ../shared


    # Services
    ./services/zfs.nix
    ./services/openssh.nix
    ./services/nextcloud.nix
    ./services/jellyfin.nix
    ./services/arr.nix
    ./services/monitoring.nix
    ./services/podman-containers.nix
    ./services/reverse-proxy.nix
    ./services/users.nix
    ./services/samba.nix
    ./services/email.nix
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
    enableIPv6 = false;

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


  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
