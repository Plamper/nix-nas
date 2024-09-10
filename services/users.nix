{ pkgs, ... }:
{
  users.users = {
    admin = {
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      initialPassword = "123";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro"
      ];
      # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = [ "wheel" "media" ];
    };
    felix = {
      initialPassword = "123";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro"
      ];

      extraGroups = [ "media" "picatures" "felix" "backup" ];
    };
    borg = {
      home = "/mnt/data-pool/Backups/borg";
      group = "backup";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro"
      ];
      isNormalUser = true;
      packages = [ pkgs.borgbackup ];
    };
  };

  users.groups = {
    backup.gid = 5000;
    media.gid = 555;
    pictures.gid = 3000;
    felix.gid = 4000;
  };
}
