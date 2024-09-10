{
  age.secrets = {
    "vpn".file = ./vpn.age;
    "cloudflare-token".file = ./cloudflare-token.age;
    "nextcloud" = {
      file = ../secrets/nextcloud.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    "nc-pg-pass" = {
      file = ../secrets/nc-pg-pass.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
  };
}
