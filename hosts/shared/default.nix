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
    statusPage = true;
    enable = true;
  };
  # Open nginx firewall Ports
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.prometheus.exporters.nginx = {
    enable = true;
    scrapeUri = "http://127.0.0.1/nginx_status";
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [
    9113
    9100
  ];

  # Expose host-level metrics to the monitoring server over the homelab VPN.
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "systemd"
      "processes"
    ];
  };

  # Collect systemd journal logs from every host and send them to the Loki instance
  # on nix-nas over the homelab VPN.
  services.alloy.enable = true;
  environment.etc."alloy/config.alloy".text = ''
    loki.write "default" {
      endpoint {
        url = "http://${
          if config.networking.hostName == "nix-nas" then "127.0.0.1" else "10.20.0.2"
        }:3030/loki/api/v1/push"
      }
    }

    loki.relabel "journal" {
      forward_to = []
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
    }

    loki.source.journal "journal" {
      max_age       = "12h"
      relabel_rules = loki.relabel.journal.rules
      labels = {
        job  = "systemd-journal",
        host = "${config.networking.hostName}",
      }
      forward_to = [loki.write.default.receiver]
    }
  '';

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
