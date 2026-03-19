{
  age.secrets = {
    "vpn".file = ./vpn.age;
    "pia".file = ./pia.age;
    "cloudflare-token".file = ./cloudflare-token.age;
    "gmail" = {
      file = ./gmail.age;
      group = "email";
    };
    # cloudnix-private-key.file = ./wireguard-keys/cloudnix-private.age;
    nix-nas-private-key.file = ./wireguard-keys/nix-nas-private.age;
    cloudflared-creds.file = ./cloudflare-creds.age;
    onlyoffice-docker-jwt.file = ./onlyoffice-docker-jwt.age;
    dyn-channel-token.file = ./dyn-channel-token.age;
    muse-env.file = ./muse-env.age;
  };
}
