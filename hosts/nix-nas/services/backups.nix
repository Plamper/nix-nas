{
  config,
  lib,
  pkgs,
  ...
}:
let
  repository = "rclone:gdrive:nix-nas-backups";

  rcloneOptions = {
    tpslimit = "8";
    tpslimit-burst = "8";
    drive-chunk-size = "64M";
    drive-pacer-min-sleep = "100ms";
    drive-use-trash = false;
  };

  commonResticArgs = {
    inherit repository rcloneOptions;
    passwordFile = config.age.secrets.restic-password.path;
    environmentFile = config.age.secrets.restic-rclone-env.path;
    extraOptions = [ "rclone.connections=4" ];
  };

  prepareScript = pkgs.writeShellApplication {
    name = "homelab-backup-prepare";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      rsync
      systemd
    ];
    text = ''
      for dir in \
        /mnt/data-pool/nextcloud \
        /mnt/data-pool/Backups/nextcloud \
        /mnt/data-pool/typst \
        /mnt/data-pool/forgejo \
        /mnt/data-pool/Backups/postgres \
        /mnt/data-pool/Backups/kanidm \
        /mnt/data-pool/Backups/borg \
        /var/lib/bitwarden_rs
      do
        if [ ! -d "$dir" ]; then
          echo "Required backup path missing: $dir" >&2
          exit 1
        fi
      done

      check_fresh_file() {
        local path="$1"
        local label="$2"
        if [ ! -s "$path" ]; then
          echo "Missing or empty dump ($label): $path" >&2
          exit 1
        fi
        if [ -z "$(find "$path" -mmin -1560 -print -quit)" ]; then
          echo "Stale dump older than 26h ($label): $path" >&2
          exit 1
        fi
      }

      check_fresh_file /mnt/data-pool/Backups/nextcloud/nextcloud.sql.gz "nextcloud postgres"
      check_fresh_file /mnt/data-pool/Backups/postgres/vaultwarden.sql.zstd "vaultwarden postgres"
      check_fresh_file /mnt/data-pool/Backups/postgres/forgejo.sql.zstd "forgejo postgres"

      if [ -z "$(find /mnt/data-pool/Backups/kanidm -maxdepth 1 -type f -mmin -1560 -size +0c -print -quit)" ]; then
        echo "No fresh Kanidm online backup (< 26h) in /mnt/data-pool/Backups/kanidm" >&2
        exit 1
      fi

      borg_repo="/mnt/data-pool/Backups/borg/mail"
      if [ -d "$borg_repo" ]; then
        for _ in $(seq 1 30); do
          if [ ! -e "$borg_repo/lock.roster" ] && [ ! -e "$borg_repo/lock.exclusive" ]; then
            break
          fi
          echo "Waiting for active Borg lock in $borg_repo..."
          sleep 10
        done
        if [ -e "$borg_repo/lock.roster" ] || [ -e "$borg_repo/lock.exclusive" ]; then
          echo "Borg repository lock still active in $borg_repo after 5 minutes" >&2
          exit 1
        fi
      fi

      # Briefly pause Typst Editor (~1-2s) for a crash-consistent local mirror
      # so Restic never reads mid-transaction SQLite/project files during upload.
      mkdir -p /mnt/data-pool/Backups/typst
      typst_was_active=0
      if systemctl is-active --quiet podman-typst-editor.service; then
        typst_was_active=1
        trap 'systemctl start podman-typst-editor.service || true' EXIT
        echo "Pausing podman-typst-editor.service for consistent rsync snapshot..."
        systemctl stop podman-typst-editor.service
      fi

      rsync -a --delete /mnt/data-pool/typst/ /mnt/data-pool/Backups/typst/

      if [ "$typst_was_active" -eq 1 ]; then
        systemctl start podman-typst-editor.service
        trap - EXIT
        echo "Restarted podman-typst-editor.service."
      fi
    '';
  };
in
{
  age.secrets = {
    restic-password = {
      file = ../../../secrets/restic-password.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    restic-rclone-env = {
      file = ../../../secrets/restic-rclone-env.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/data-pool/Backups/typst 0750 root root -"
  ];

  services.restic.backups = {
    homelab = commonResticArgs // {
      initialize = true;
      backupPrepareCommand = "${lib.getExe prepareScript}";
      paths = [
        "/mnt/data-pool/nextcloud"
        "/mnt/data-pool/Backups/nextcloud"
        "/mnt/data-pool/Backups/typst"
        "/mnt/data-pool/forgejo"
        "/mnt/data-pool/Backups/postgres"
        "/mnt/data-pool/Backups/kanidm"
        "/mnt/data-pool/Backups/borg"
        "/var/lib/bitwarden_rs"
      ];
      exclude = [
        "/mnt/data-pool/nextcloud/data/appdata_*/preview"
        "/mnt/data-pool/nextcloud/data/*/cache"
        "/mnt/data-pool/nextcloud/data/*/uploads"
        "*.part"
        "/mnt/data-pool/Backups/nextcloud/*.prev.*"
        "/mnt/data-pool/Backups/nextcloud/*.in-progress.*"
        "/mnt/data-pool/Backups/postgres/*.prev.*"
        "/mnt/data-pool/Backups/postgres/*.in-progress.*"
        "/mnt/data-pool/forgejo/log"
        "/mnt/data-pool/forgejo/data/tmp"
        "/mnt/data-pool/forgejo/data/indexers"
        "/mnt/data-pool/forgejo/dump"
        "/var/lib/bitwarden_rs/icon_cache"
        "/var/lib/bitwarden_rs/tmp"
      ];
      extraBackupArgs = [
        "--pack-size=32"
        "--exclude-caches"
      ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 3"
      ];
      timerConfig = {
        OnCalendar = "*-*-* 03:00:00";
        RandomizedDelaySec = "15m";
        Persistent = true;
      };
    };

    homelab-check = commonResticArgs // {
      paths = [ ];
      createWrapper = false;
      checkOpts = [ "--read-data-subset=5%" ];
      timerConfig = {
        OnCalendar = "Sun *-*-* 05:00:00";
        Persistent = true;
      };
    };
  };

  systemd.services."backup-notify-failure@" = {
    description = "Send email alert on backup failure for %i";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      NoNewPrivileges = true;
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      LockPersonality = true;
    };
    scriptArgs = "%i";
    script = ''
      unit="$1"
      logs="$(${pkgs.systemd}/bin/journalctl -u "$unit" -n 80 --no-pager || true)"
      ${pkgs.msmtp}/bin/sendmail -t <<EOF
      From: noreply@plamper.org
      To: admin@plamper.org
      Subject: [${config.networking.hostName}] Backup failure: $unit

      Systemd unit $unit failed on ${config.networking.hostName}.

      Recent logs:
      $logs
      EOF
    '';
  };

  systemd.services = {
    "restic-backups-homelab".unitConfig = {
      RequiresMountsFor = [ "/mnt/data-pool" ];
      OnFailure = "backup-notify-failure@%N.service";
    };
    "restic-backups-homelab-check".unitConfig = {
      OnFailure = "backup-notify-failure@%N.service";
    };
    "postgresqlBackup-vaultwarden".unitConfig = {
      RequiresMountsFor = [ "/mnt/data-pool" ];
      OnFailure = "backup-notify-failure@%N.service";
    };
    "postgresqlBackup-forgejo".unitConfig = {
      RequiresMountsFor = [ "/mnt/data-pool" ];
      OnFailure = "backup-notify-failure@%N.service";
    };
    "prometheus-restic-exporter" = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        RestartSec = "5m";
      };
    };
  };

  services.prometheus.exporters.restic = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9753;
    inherit repository;
    passwordFile = config.age.secrets.restic-password.path;
    environmentFile = config.age.secrets.restic-rclone-env.path;
    refreshInterval = 21600;
    rcloneOptions = {
      tpslimit = "8";
      tpslimit-burst = "8";
      drive-pacer-min-sleep = "100ms";
    };
  };
}
