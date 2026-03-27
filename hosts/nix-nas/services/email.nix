{ config, ... }:
{

  age.secrets.smtp-password = {
    file = ../../../secrets/noreply-smtp-password.age;
  };

  environment.etc."/aliases".text = "root: admin@plamper.org";

  services.mail.sendmailSetuidWrapper.enable = true;

  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/etc/aliases";
      port = 465;
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      tls = "on";
      auth = "login";
      tls_starttls = "off";
    };
    accounts = {
      default = {
        host = "mail.plamper.org";
        # smartmontools can only access sed not cat
        passwordeval = "sed '' ${config.age.secrets.smtp-password.path}";
        user = "noreply@plamper.org";
        from = "noreply@plamper.org";
      };
    };
  };
}
