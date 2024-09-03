let
  pc-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro";
  test-vm-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKOkz3z5Cox7eZy2YFLIEN5EqvONDqGJoZdxhi4ISjcc";
in
{
  "vpn.env.age".publicKeys = [ pc-key test-vm-key ];
  "cloudflare-token.age".publicKeys = [ pc-key test-vm-key ];
}
