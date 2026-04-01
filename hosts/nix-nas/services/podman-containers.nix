{ config, pkgs, ... }:
{

  virtualisation.oci-containers.containers.muse = {
    image = "docker.io/dovah/muse";
    volumes = [
      "/var/muse:/data"
    ];
    environmentFiles = [
      config.age.secrets.muse-env.path
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/homarr/configs 0770 root root -"
    "d /var/homarr/data 0770 root root -"
    "d /var/homarr/icons 0770 root root -"
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

  virtualisation.oci-containers.containers.onlyoffice = {
    image = "onlyoffice/documentserver";
    ports = [ "7979:80" ];
    environmentFiles = [
      config.age.secrets.onlyoffice-docker-jwt.path
    ];
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

  # from https://discourse.nixos.org/t/updating-oci-container-images/30029/4
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "update-containers" ''
      	SUDO=""
      	if [[ $(id -u) -ne 0 ]]; then
      		SUDO="sudo"
      	fi

          images=$($SUDO ${pkgs.podman}/bin/podman ps -a --format="{{.Image}}" | sort -u)

          for image in $images
          do
            $SUDO ${pkgs.podman}/bin/podman pull $image
          done
    '')
  ];
  systemd.timers = {
    updatecontainers = {
      timerConfig = {
        Unit = "updatecontainers.service";
        OnCalendar = "Mon 02:00";
      };
      wantedBy = [ "timers.target" ];
    };
  };

  systemd.services = {
    updatecontainers = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "update-containers";
      };
    };
  };
}
