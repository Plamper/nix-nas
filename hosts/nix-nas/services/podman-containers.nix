{ config, pkgs, ... }:
{
  users.users.podman = {
    isSystemUser = true;
    group = "podman";
    home = "/var/lib/podman";
    createHome = true;
    uid = 995;
    autoSubUidGidRange = true;
    linger = true;
  };

  users.groups.podman = {
    gid = 995;
  };

  age.secrets.muse-env = {
    owner = "podman";
    group = "podman";
  };

  age.secrets.onlyoffice-docker-jwt = {
    owner = "podman";
    group = "podman";
  };

  age.secrets.typst-editor-invite-token = {
    file = ../../../secrets/typst-editor-invite-token.age;
    owner = "podman";
    group = "podman";
  };

  virtualisation.oci-containers.containers.muse = {
    image = "ghcr.io/museofficial/muse";
    podman.user = "podman";
    capabilities.ALL = false;
    extraOptions = [
      "--security-opt=no-new-privileges"
    ];
    volumes = [
      "/var/muse:/data"
    ];
    environmentFiles = [
      config.age.secrets.muse-env.path
    ];
    labels."io.containers.autoupdate" = "registry";
  };

  systemd.tmpfiles.rules = [
    "d /var/muse 0770 podman podman -"
    "Z /var/muse 0770 podman podman -"
    "d /mnt/data-pool/typst 0770 podman podman -"
    "Z /mnt/data-pool/typst 0770 podman podman -"
  ];

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    fira-sans
    geist-font
    inter
    roboto
    roboto-serif
    corefonts
    vista-fonts
    vista-fonts-chs
    vista-fonts-cht
    noto-fonts
  ];

  virtualisation.oci-containers.containers.euro-office = {
    image = "ghcr.io/euro-office/documentserver:latest";
    podman.user = "podman";
    ports = [ "7979:80" ];
    capabilities = {
      MKNOD = false;
      NET_RAW = false;
      AUDIT_WRITE = false;
    };
    extraOptions = [
      "--security-opt=no-new-privileges"
    ];
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
        "${pkgs.corefonts}/share/fonts/truetype:/usr/share/fonts/truetype/corefonts/:ro"
        "${pkgs.vista-fonts}/share/fonts/truetype:/usr/share/fonts/truetype/vista-fonts/:ro"
        "${pkgs.vista-fonts-chs}/share/fonts/truetype:/usr/share/fonts/truetype/vista-fonts-chs/:ro"
        "${pkgs.vista-fonts-cht}/share/fonts/truetype:/usr/share/fonts/truetype/vista-fonts-cht/:ro"
        "${pkgs.noto-fonts}/share/fonts/noto:/usr/share/fonts/noto/:ro"
      ];
  };

  # Configure the OCI Container
  virtualisation.oci-containers.containers."typst-editor" = {
    image = "ghcr.io/fl-grtg/typst-editor:main";
    autoStart = true;
    podman.user = "podman";
    user = "999:999";
    capabilities.ALL = false;

    ports = [
      "0.0.0.0:8978:8978"
    ];

    environment = {
      DATA_DIR = "/app/data";
      HOST = "0.0.0.0";
      PORT = "8978";
    };

    environmentFiles = [ config.age.secrets.typst-editor-invite-token.path ];

    volumes = [
      "/mnt/data-pool/typst:/app/data:U"
    ];

    extraOptions = [
      "--security-opt=no-new-privileges"
      "--stop-timeout=15"
      "--log-opt=max-size=10m"
    ];
  };

  systemd.services.podman-auto-update = {
    description = "Podman auto-update";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman auto-update";
      User = "podman";
    };
    environment = {
      HOME = config.users.users.podman.home;
      XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.podman.uid}";
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
