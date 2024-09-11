{ config, ... }:
{
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
        host = "smtp.gmail.com";
        passwordeval = "cat ${config.age.secrets."gmail".path}";
        user = "g9922590@gmail.com";
        from = "g9922590@gmail.com";
      };
    };
  };
}