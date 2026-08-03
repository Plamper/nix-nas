{
  inputs,
  lib,
  pkgs,
  config,
  agenix,
  ...
}:
{


  # Stuff thats should be present on all hosts

  environment.systemPackages = (
    with pkgs;
    [
      git
      nixd
      nixfmt
      dig
      helix
      lazygit
      agenix.packages.${pkgs.system}.default
    ]
  );

  time.timeZone = lib.mkDefault "Europe/Berlin";

  # Configure ACME appropriately for all servers
  security.acme.acceptTerms = true;
  security.acme.defaults = {
    email = "felix.plamper@tuta.io";
    dnsResolver = "1.1.1.1:53";
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets."cloudflare-token".path;
    extraLegoFlags = [ "--dns.propagation-wait=120s" ]; # Dns Propagation check does not work
  };

  # All servers have default nginx set
  services.nginx = {
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    enable = true;
  };
  # Open nginx firewall Ports
  networking.firewall.allowedTCPPorts = [ 80 443 ];

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

        trusted-users = [ "@wheel" ];
      };
      # Opinionated: disable channels
      channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

}
