let
  pc-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro";
  test-vm-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMVaNdLGdOsuczVoGG9jhtRI02kt+PgCdo5Mfhcn+OwN";
  test-vm-key-admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwN68PStruvwNlb91jPuUlhLQyCgKP/umNGo1Bo+d5G";
  keys = [ pc-key test-vm-key test-vm-key-admin ];
in
{
  "vpn.env.age".publicKeys = keys;
  "cloudflare-token.age".publicKeys = keys;
  "nextcloud.age".publicKeys = keys;
}
