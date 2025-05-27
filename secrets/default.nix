{
  age.secrets = {
    "vpn".file = ./vpn.age;
    "cloudflare-token".file = ./cloudflare-token.age;
    "gmail" = {
      file = ./gmail.age;
      group = "email";
    };
    # cloudnix-private-key.file = ./wireguard-keys/cloudnix-private.age;
    nix-nas-private-key.file = ./wireguard-keys/nix-nas-private.age;
  };
}
