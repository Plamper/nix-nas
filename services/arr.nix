# Auto-generated using compose2nix v0.2.1-pre.
# Then manually adjusted
{ pkgs, lib, config,... }:
{
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };
  virtualisation.oci-containers.backend = "podman";

  # Containers
  virtualisation.oci-containers.containers."arr-sonarr" = {
    image = "ghcr.io/hotio/sonarr:latest";
    environment = {
      PGID = "1000";
      PUID = "1000";
      TZ = "Europe/Amsterdam";
    };
    volumes = [
      "/data:/data:rw"
      "/<host_folder_config>:/config"
    ];
    ports = [
      "8989:8989/tcp"
    ];
    dependsOn = [
      "arr-vpn"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network=container:arr-vpn"
    ];
  };
  systemd.services."podman-arr-sonarr" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    partOf = [
      "podman-compose-arr-root.target"
    ];
    wantedBy = [
      "podman-compose-arr-root.target"
    ];
  };
  virtualisation.oci-containers.containers."arr-vpn" = {
    image = "thrnz/docker-wireguard-pia";
    environment = {
      LOC = "swiss";
      LOCAL_NETWORK = "192.168.1.0/24";
      PORT_FORWARDING = "1";
    };
    environmentFiles = [
      config.age.secrets."vpn.env".path
    ];
    volumes = [
      "arr_pia:/pia:rw"
      "arr_pia-shared:/pia-shared:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--health-cmd=ping -c 1 www.google.com || exit 1"
      "--health-interval=30s"
      "--health-retries=3"
      "--health-timeout=10s"
      "--network-alias=vpn"
      "--network=arr_default"
      "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
      "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      "--sysctl=net.ipv6.conf.default.disable_ipv6=1"
      "--sysctl=net.ipv6.conf.lo.disable_ipv6=1"
    ];
  };
  systemd.services."podman-arr-vpn" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-arr_default.service"
      "podman-volume-arr_pia-shared.service"
      "podman-volume-arr_pia.service"
    ];
    requires = [
      "podman-network-arr_default.service"
      "podman-volume-arr_pia-shared.service"
      "podman-volume-arr_pia.service"
    ];
    partOf = [
      "podman-compose-arr-root.target"
    ];
    wantedBy = [
      "podman-compose-arr-root.target"
    ];
  };
  virtualisation.oci-containers.containers."qbittorrent" = {
    image = "lscr.io/linuxserver/qbittorrent:latest";
    environment = {
      TZ = "Etc/UTC";
      WEBUI_PORT= "8080";
    };
    volumes = [
      "/<yourpath>/config:/config:rw"
      "/<yourpath>/downloads:/downloads:rw"
    ];
    ports = [
      "8888:8080/tcp"
    ];
    dependsOn = [
      "arr-vpn"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network=container:arr-vpn"
    ];
  };
  systemd.services."podman-qbittorrent" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    partOf = [
      "podman-compose-arr-root.target"
    ];
    wantedBy = [
      "podman-compose-arr-root.target"
    ];
  };
  virtualisation.oci-containers.containers."qbittorrent-port" = {
    image = "charlocharlie/qbittorrent-port-forward-file:latest";
    environment = {
      PORT_FILE = "/pia-shared/port.dat";
      QBT_ADDR = "http://localhost:8888";
      QBT_PASSWORD = "admin";
      QBT_USERNAME = "test";
    };
    volumes = [
      "arr_pia-shared:/pia-shared:ro"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=qbittorrent-port"
      "--network=arr_default"
    ];
  };
  systemd.services."podman-qbittorrent-port" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-arr_default.service"
      "podman-volume-arr_pia-shared.service"
    ];
    requires = [
      "podman-network-arr_default.service"
      "podman-volume-arr_pia-shared.service"
    ];
    partOf = [
      "podman-compose-arr-root.target"
    ];
    wantedBy = [
      "podman-compose-arr-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-arr_default" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f arr_default";
    };
    script = ''
      podman network inspect arr_default || podman network create arr_default
    '';
    partOf = [ "podman-compose-arr-root.target" ];
    wantedBy = [ "podman-compose-arr-root.target" ];
  };

  # Volumes
  systemd.services."podman-volume-arr_pia" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect arr_pia || podman volume create arr_pia
    '';
    partOf = [ "podman-compose-arr-root.target" ];
    wantedBy = [ "podman-compose-arr-root.target" ];
  };
  systemd.services."podman-volume-arr_pia-shared" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect arr_pia-shared || podman volume create arr_pia-shared
    '';
    partOf = [ "podman-compose-arr-root.target" ];
    wantedBy = [ "podman-compose-arr-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-arr-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
