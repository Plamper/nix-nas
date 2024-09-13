{
  age.secrets = {
    "vpn".file = ./vpn.age;
    "cloudflare-token".file = ./cloudflare-token.age;
    "gmail" = {
      file = ./gmail.age;
      group = "email";
    };
  };
}
