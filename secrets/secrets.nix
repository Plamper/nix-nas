let
  pc-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro";
  nas-admin-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPwAlKNggifROXV1CBjjVNwgkSSa3t15muTo40ZeysS";
  nas-host-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJQddURjXQPlTzWOB+cwTGCTcOliJUY44hfe3YtD8pP";
  cloudnix-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGSyXZ/ceJRilbbX3CMveGLZV1TXWQY0oUPq4hTGKTP";
  keys = [ pc-key nas-admin-key nas-host-key cloudnix-key ];
in
{
  "vpn.age".publicKeys = keys;
  "cloudflare-token.age".publicKeys = keys;
  "nextcloud.age".publicKeys = keys;
  "nc-pg-pass.age".publicKeys = keys;
  "onlyoffice-jwt.age".publicKeys = keys;
  "gmail.age".publicKeys = keys;
  "cloudflare-creds.age".publicKeys = [ nas-host-key pc-key ];
  "wireguard-keys/cloudnix-private.age".publicKeys = [ cloudnix-key pc-key ];
  "wireguard-keys/nix-nas-private.age".publicKeys = [ nas-host-key pc-key ];
  "wireguard-keys/nextcloud-private.age".publicKeys = [ nas-host-key pc-key ];
}
