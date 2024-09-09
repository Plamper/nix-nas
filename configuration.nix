{ inputs
, lib
, config
, pkgs
, modulesPath
, ...
}: {

  imports = [
    # (modulesPath + "/virtualisation/virtualbox-image.nix")
    ./hardware-configuration.nix
    ./secrets

    ./services/zfs.nix

    # Services
    ./services/openssh.nix
    # ./services/nextcloud.nix
    ./services/jellyfin.nix
    ./services/arr.nix
    ./services/monitoring.nix
    # ./services/podman-containers.nix
    ./services/reverse-proxy.nix
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

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";
        # Opinionated: disable global registry
        flake-registry = "";
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
      };
      # Opinionated: disable channels
      channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  networking.hostName = "nix-nas";


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users = {
    admin = {
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      initialPassword = "123";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro"
      ];
      # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = [ "wheel" "media" ];
    };
  };

  programs.nix-ld.enable = true;

  networking = {

    firewall.enable = true;

    # nameservers = [ "1.1.1.1" "8.8.8.8" ];

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp2s0";
      # Lazy IPv6 connectivity for the containe
    };
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    openFirewall = true;
  };

  environment.systemPackages = (with pkgs;[
    git
    nixd
    nixpkgs-fmt
  ]) ++ [
    inputs.agenix.packages.x86_64-linux.default
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
