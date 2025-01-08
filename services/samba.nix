{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "nix-nas";
        "netbios name" = "nix-nas";
        security = "user";
        #use sendfile = yes
        "min protocol" = "smb2";
        # note: localhost is the ipv6 localhost ::1
        "hosts allow" = "192.168.1. 127.0.0.1 100. localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      Felix = {
        path = "/mnt/data-pool/Felix";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force user" = "felix";
        "force group" = "felix";
        "valid users" = "felix";
      };
      Pictures = {
        path = "/mnt/data-pool/Pictures";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force group" = "pictures";
        "valid users" = "@pictures";
      };
      Video = {
        path = "/mnt/data-pool/media/Video";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force group" = "media";
        "valid users" = "@media";
      };
      Music = {
        path = "/mnt/data-pool/media/Music";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force group" = "media";
        "valid users" = "@media";
      };
      Media = {
        path = "/mnt/data-pool/media/";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force group" = "media";
        "valid users" = "@media";
      };
      Backups = {
        path = "/mnt/data-pool/Backups/";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force group" = "backup";
        "valid users" = "@backup";
      };
      Roms = {
        path = "/mnt/data-pool/Roms/";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force group" = "roms";
        "valid users" = "@roms";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
    discovery = true;
    interface = "enp2s0";
  };

}
