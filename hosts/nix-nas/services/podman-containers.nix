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
    ports = [ "127.0.0.1:7979:80" ];
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
      "127.0.0.1:8978:8978"
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

    labels."io.containers.autoupdate" = "registry";
  };

  systemd.services.podman-auto-update =
    let
      updateScript = pkgs.writeShellApplication {
        name = "podman-auto-update";
        runtimeInputs = [
          config.virtualisation.podman.package
          pkgs.coreutils
        ];
        text = ''
          runtime_dir="''${RUNTIME_DIRECTORY:-/run/podman-auto-update}"
          outfile="$runtime_dir/dry-run.out"
          errfile="$runtime_dir/dry-run.err"
          pull_out="$runtime_dir/pull.out"
          pull_err="$runtime_dir/pull.err"
          restart_file="$runtime_dir/restart-units"

          run_logged() {
            local out="$1" err="$2" rc=0
            shift 2
            "$@" </dev/null >"$out" 2>"$err" || rc=$?
            [ ! -s "$err" ] || cat "$err" >&2
            if [ "$rc" -ne 0 ]; then
              [ ! -s "$out" ] || cat "$out" >&2
              exit "$rc"
            fi
            [ ! -s "$out" ] || cat "$out"
          }

          rm -f "$outfile" "$errfile" "$pull_out" "$pull_err" "$restart_file"

          # Check registry digests without invoking rootless RestartUnit:
          # NixOS oci-containers define system units, which do not exist on systemd --user.
          run_logged "$outfile" "$errfile" podman auto-update --dry-run --format '{{.Unit}}|{{.Image}}|{{.Updated}}'

          while IFS='|' read -r unit image updated; do
            [ -n "$image" ] || continue
            if [ "$updated" = "failed" ]; then
              echo "podman auto-update reported failed status for $unit ($image)" >&2
              exit 1
            fi
            [ "$updated" = "pending" ] || continue

            echo "Pulling updated image $image for $unit..."
            run_logged "$pull_out" "$pull_err" podman pull "$image"

            if [[ "$unit" =~ ^podman-[a-zA-Z0-9_.@-]+\.service$ ]]; then
              printf '%s\n' "$unit" >> "$restart_file"
            else
              echo "Refusing unexpected unit name '$unit'" >&2
              exit 1
            fi
          done < "$outfile"
        '';
      };
      restartScript = pkgs.writeShellApplication {
        name = "podman-auto-update-restart";
        runtimeInputs = [ pkgs.systemd ];
        text = ''
          runtime_dir="''${RUNTIME_DIRECTORY:-/run/podman-auto-update}"
          restart_file="$runtime_dir/restart-units"
          [ -s "$restart_file" ] || exit 0
          while IFS= read -r unit; do
            [ -n "$unit" ] || continue
            echo "Restarting updated service $unit..."
            systemctl restart "$unit" </dev/null
          done < "$restart_file"
        '';
      };
    in
    {
      description = "Podman auto-update";
      after = [
        "network-online.target"
        "user@${toString config.users.users.podman.uid}.service"
      ];
      wants = [
        "network-online.target"
        "user@${toString config.users.users.podman.uid}.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = [
          ""
          "${updateScript}/bin/podman-auto-update"
        ];
        ExecStartPost = [
          ""
          "+${restartScript}/bin/podman-auto-update-restart"
        ];
        User = "podman";
        Group = "podman";
        RuntimeDirectory = "podman-auto-update";
        # Omit NoNewPrivileges/RestrictNamespaces/RestrictSUIDSGID for rootless newuidmap,
        # omit ProtectHome because systemd's ProtectHome blocks /run/user/<uid>,
        # and omit PrivateDevices so fuse-overlayfs retains /dev/fuse access.
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
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
