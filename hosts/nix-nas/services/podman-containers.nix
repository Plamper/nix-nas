{ pkgs, ... }:
{
  virtualisation.oci-containers.containers.homarr = {
    image = "ghcr.io/ajnart/homarr:latest";
    ports = [ "7575:7575" ];
    volumes = [
      "/var/homarr/configs:/app/data/configs"
      "/var/homarr/data:/data"
      "/var/homarr/icons:/app/public/icons"
    ];
  };

  systemd.tmpfiles.rules = [
        "d /var/homarr/configs 0770 root root -"
        "d /var/homarr/data 0770 root root -"
        "d /var/homarr/icons 0770 root root -"
  ];

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
