{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true; # exponentially increase ban time for repeat offenders
      factor = "4";
      maxtime = "168h"; # cap at 1 week
    };

    jails = {
      dovecot.settings = {
        enabled = true; # covers IMAP brute force
        maxretry = 5;
      };
      postfix.settings = {
        enabled = true; # covers rejected SMTP requests
        maxretry = 5;
      };
      postfix-sasl.settings = {
        enabled = true; # covers SMTP authentication brute force
        maxretry = 5;
      };
    };
  };
}
