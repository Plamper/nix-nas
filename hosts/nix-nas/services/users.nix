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

      extraGroups = [ "media" "pictures" "felix" "backup" "roms" ];
    };
    borg = {
      home = "/mnt/data-pool/Backups/borg";
      group = "backup";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKqykgN7RuOz+6YCDWYTeXfGKRHT5VXG/LJWGN1zFro"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH54va+KM5cbZgmLjtW0Ppm08d5i9ZMgAIr9/KanrePj"
      ];
      isNormalUser = true;
      packages = [ pkgs.borgbackup ];
    };
  };

    # Enable passwordless sudo.
  security.sudo.extraRules = [
    {
      users = [ "admin" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];


  users.groups = {
    backup.gid = 5000;
    media.gid = 555;
    pictures.gid = 3000;
    felix.gid = 4000;
    roms.gid = 6000;
    email.gid = 777;
  };
}
