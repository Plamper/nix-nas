{ config, pkgs, ... }:
{

  virtualisation.oci-containers.containers.muse = {
    image = "ghcr.io/museofficial/muse";
    volumes = [
      "/var/muse:/data"
    ];
    environmentFiles = [
      config.age.secrets.muse-env.path
    ];
    labels."io.containers.autoupdate" = "registry";
  };

  systemd.tmpfiles.rules = [
    "d /var/muse 0770 root root -"
  ];

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    fira-sans
    geist-font
    inter
    roboto
    roboto-serif
  ];

  virtualisation.oci-containers.containers.euro-office = {
    image = "ghcr.io/euro-office/documentserver:latest";
    ports = [ "7979:80" ];
    environmentFiles = [
      config.age.secrets.onlyoffice-docker-jwt.path
    ];
    labels."io.containers.autoupdate" = "registry";
    volumes =
      let
        noto-cjk-serif = pkgs.fetchzip {
          url = "https://github.com/notofonts/noto-cjk/releases/download/Serif2.003/05_NotoSerifCJKOTF.zip";
          hash = "sha256-yZfDZ3tHIgp/GPLbYJ5GQqS7pThC1kW8lxSv23AFVpQ=";
          stripRoot = false;
        };
        noto-cjk-sans = pkgs.fetchzip {
          url = "https://github.com/notofonts/noto-cjk/releases/download/Sans2.004/04_NotoSansCJK-OTF.zip";
          hash = "sha256-lWhQ5/KNS01sr7m0hmt1kO4jnvLcxN++BP489XlfwAc=";
          stripRoot = false;
        };
      in
      [
        "${pkgs.geist-font}/share/fonts/opentype:/usr/share/fonts/opentype/geist/:ro"
        "${pkgs.fira-sans}/share/fonts/opentype:/usr/share/fonts/opentype/fira-sans/:ro"
        "${noto-cjk-sans}/OTF:/usr/share/fonts/opentype/noto-cjk-sans/:ro"
        "${noto-cjk-serif}/OTF:/usr/share/fonts/opentype/noto-cjk-serif/:ro"
        "${pkgs.inter}/share/fonts/truetype:/usr/share/fonts/truetype/inter/:ro"
        "${pkgs.roboto}/share/fonts/truetype:/usr/share/fonts/truetype/roboto/:ro"
        "${pkgs.roboto-serif}/share/fonts/truetype:/usr/share/fonts/truetype/roboto-serif/:ro"
      ];
  };

  systemd.services.podman-auto-update = {
    description = "Podman auto-update";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman auto-update";
    };
  };

  systemd.timers.podman-auto-update = {
    description = "Podman auto-update timer";
    timerConfig = {
      OnCalendar = "Mon 02:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}
