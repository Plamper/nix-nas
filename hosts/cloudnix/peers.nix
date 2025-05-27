{
  # List of allowed peers.
  wg-peers = [
    {
      # nextcloud
      publicKey = "5hXTHcTOW3fHUtt3EWXgsSZjBBEADJvAceiHLKnd0Hg=";
      allowedIPs = [ "10.20.0.4/32" ];
    }
    {
      # Nix-nas
      publicKey = "KjkgTzfEeoS5ORYkAGmkwPqrhr5RczPeE1zA6YoQE3E=";
      allowedIPs = [ "10.20.0.2/32" ];
    }
    {
      # Smartphone
      publicKey = "e1qNW4hSkrJ0bcSQjZAjsKgJtlHZVXjAHW2900pJDSY=";
      allowedIPs = [ "10.20.0.3/32" ];
    }
  ];
}
