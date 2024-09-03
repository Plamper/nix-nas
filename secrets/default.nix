{ inputs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];
  age.secrets = {
    "vpn.env".file = ./vpn.env.age;
    "cloudflare-token".file = ./cloudflare-token.age;
  };
}
