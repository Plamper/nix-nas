{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../shared
    ../../secrets/vpnnix.nix
    ./headscale.nix
  ];

  # Build EFI image for OCI UEFI_64 launch capability
  oci.efi = true;
  virtualisation.diskSize = 8 * 1024;

  networking.hostName = "vpnnix";

  services.cloud-init.enable = true;

  # Swap configuration for 1 GB RAM E2.1.Micro instance
  zramSwap.enable = true;
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 2048;
    }
  ];

  users = {
    mutableUsers = false;
    users."admin" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro felix@pc"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZqZT56NXAYDGmAa+UEtjeJ397awyetFlI29+3t9kg3"
      ];
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Do not override local DNS on the Headscale server itself so it always resolves
    # idm.plamper.org publicly via Cloudflare Tunnel on startup.
    extraSetFlags = [ "--accept-dns=false" ];
  };
  networking.firewall.trustedInterfaces = [
    config.services.tailscale.interfaceName
  ];

  security.sudo.extraRules = [
    {
      users = [ "admin" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.getty.autologinUser = null;
  documentation.enable = false;

  system.stateVersion = "26.05";
}
