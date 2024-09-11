{
  age.secrets = {
    "vpn".file = ./vpn.age;
    "cloudflare-token".file = ./cloudflare-token.age;
    "nextcloud" = {
      file = ./nextcloud.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    "nc-pg-pass" = {
      file = ./nc-pg-pass.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    "gmail" = {
      file = ./gmail.age;
      group = "email";
    };
  };
}
