{
  config,
  pkgs,
  ...
}:
{

  # enable NAT
  networking.nat.enable = true;
  networking.nat.externalInterface = "enp0s6";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
  };

  networking.wireguard.enable = true;
  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.20.0.1/24" ];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 51820;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.20.0.0/24 -o enp0s6 -j MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.20.0.0/24 -o enp0s6 -j MASQUERADE
      '';

      # Path to the private key file.
      privateKeyFile = config.age.secrets.cloudnix-private-key.path;

      peers =
        let
          file = import ./peers.nix;
        in
        file.wg-peers;
    };
  };
}
