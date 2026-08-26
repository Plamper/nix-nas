{ config, ... }:
{
  age.secrets."vaultwarden-oidc-secret" = {
    file = ../../../secrets/vaultwarden-oidc-secret.age;
    owner = "vaultwarden";
    mode = "440";
  };
  age.secrets."vaultwarden-smtp-secret" = {
    file = ../../../secrets/vaultwarden-smtp-secret.age;
    owner = "vaultwarden";
    mode = "440";
  };

  services.nginx.virtualHosts."pass.plamper.org" = {
    enableACME = true;
    forceSSL = true;
    acmeRoot = null;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };
  };

  services.vaultwarden = {
    enable = true;
    environmentFile = [
      config.age.secrets."vaultwarden-oidc-secret".path
      config.age.secrets."vaultwarden-smtp-secret".path
    ];
    configurePostgres = true;
    dbBackend = "postgresql";
    config = {
      # Refer to https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
      DOMAIN = "https://pass.plamper.org";
      SIGNUPS_ALLOWED = false;

      SSO_ENABLED = true;
      SSO_SIGNUPS_ALLOWED = true;
      SSO_AUTHORITY = "https://idm.plamper.org/oauth2/openid/vaultwarden";
      SSO_CLIENT_ID = "vaultwarden";

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      SMTP_HOST = "mail.plamper.org";
      SMTP_PORT = 465;
      SMTP_SECURITY="force_tls";

      SMTP_USERNAME = "noreply@plamper.org";
      SMTP_FROM = "noreply@plamper.org";
      SMTP_FROM_NAME = "Plamper.org Vaultwarden";
    };
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [ "vaultwarden" ];
    location = "/mnt/data-pool/Backups/vaultwarden";
    startAt = "*-*-* 01:15:00";
  };

  systemd.tmpfiles.rules = [
    "d /mnt/data-pool/Backups/vaultwarden 0700 postgres postgres -"
  ];
}
