{ config, ... }:
{
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
    backupDir = "/var/local/vaultwarden/backup";
    environmentFile = "/var/lib/vaultwarden/vaultwarden.env";
    config = {
      # Refer to https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
      DOMAIN = "https://pass.plamper.org";
      SIGNUPS_ALLOWED = false;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";

      SMTP_HOST = "mail.plamper.org";
      SMTP_PORT = 465;
      SMTP_SSL = true;

      SMTP_FROM = "noreply@plamper.org";
      SMTP_FROM_NAME = "Plamper.org Vaultwarden";
    };
  };
}
