{
  config,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/oci-common.nix")
    ../shared
    ../../secrets/mailnix.nix
    ./mailserver.nix
  ];

  # EFI setup matching the vpnnix OCI image
  oci.efi = true;

  networking.hostName = "mailnix";

  # networkd enables systemd-resolved by default, which disables resolvconf and
  # routes queries through OCI DNS instead of snm's local kresd (breaking DNSSEC/Rspamd DNSBL).
  services.resolved.enable = false;

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
    # Prevent Headscale's override_local_dns (1.1.1.1/9.9.9.9) from bypassing kresd
    # on 127.0.0.1, which breaks DNSSEC/DANE and triggers Spamhaus DNSBL blocks.
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
