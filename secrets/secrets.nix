let
  pc-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro";
  nas-admin-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPwAlKNggifROXV1CBjjVNwgkSSa3t15muTo40ZeysS";
  nas-host-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJQddURjXQPlTzWOB+cwTGCTcOliJUY44hfe3YtD8pP";
  cloudnix-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGSyXZ/ceJRilbbX3CMveGLZV1TXWQY0oUPq4hTGKTP";
  bitwarden-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZqZT56NXAYDGmAa+UEtjeJ397awyetFlI29+3t9kg3";
  keys = [ pc-key nas-admin-key nas-host-key cloudnix-key bitwarden-key ];
in
{
  "vpn.age".publicKeys = keys;
  "pia.age".publicKeys = keys;
  "pia-env.age".publicKeys = keys;
  "cloudflare-token.age".publicKeys = keys;
  "nextcloud.age".publicKeys = keys;
  "nc-pg-pass.age".publicKeys = keys;
  "onlyoffice-jwt.age".publicKeys = keys;
  "onlyoffice-docker-jwt.age".publicKeys = keys;
  "gmail.age".publicKeys = keys;
  "dyn-channel-token.age".publicKeys = keys;
  "muse-env.age".publicKeys = keys;
  "lldap_user_pass.age".publicKeys = keys;
  "lldap_jwt_secret.age".publicKeys = keys;
  "lldap-priv-key.age".publicKeys = keys;
  "cloudflare-creds.age".publicKeys = [ nas-host-key pc-key ];
  "wireguard-keys/cloudnix-private.age".publicKeys = [ cloudnix-key pc-key ];
  "wireguard-keys/nix-nas-private.age".publicKeys = [ nas-host-key pc-key ];
  "wireguard-keys/nextcloud-private.age".publicKeys = [ nas-host-key pc-key ];
  "authelia-jwt.age".publicKeys = keys;
  "authelia-storageEncryptionKey.age".publicKeys = keys;
  "authelia-sessionSecret.age".publicKeys = keys;
  "authelia-oidcHmacSecret.age".publicKeys = keys;
  "authelia-oidcIssuerPrivateKey.age".publicKeys = keys;
  "authelia-nextCloudOidcSecret.age".publicKeys = keys;
  "postfix-sasl-passwd.age".publicKeys = keys;
  "noreply-smtp-password.age".publicKeys = keys;
  "dovecot-masterpassword.age".publicKeys = keys;
  "vaultwarden.env.age".publicKeys = keys;
}
