{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "plamper.org";
  ociSmtp = "smtp.email.eu-frankfurt-1.oci.oraclecloud.com";
in
{
  imports = [
    inputs.snm.nixosModules.default
    inputs.email-autoconfig.nixosModules.default
  ];

  age.secrets = {
    lldap_pass = {
      file = ../../secrets/lldap_user_pass.age;
      owner = "root";
      group = "root";
      mode = "0600";
    };
    kanidm-mail-ldap = {
      file = ../../secrets/kanidm-mail-ldap.age;
      owner = "root";
      group = "root";
      mode = "0600";
    };
    dovecot-masteruser = {
      file = ../../secrets/dovecot-masterpassword.age;
      owner = "dovecot2";
      group = "dovecot2";
      mode = "0600";
    };
    smtp_pass = {
      # [smtp.email.eu-frankfurt-1.oci.oraclecloud.com]:587 SMTP_USERNAME:SMTP_PASSWORD
      file = ../../secrets/postfix-sasl-passwd.age;
      group = "postfix";
    };
  };

  # Get acme cert
  security.acme.certs."${config.mailserver.fqdn}" = {
    domain = config.mailserver.fqdn;
  };

  # Setup mailserver
  mailserver = {
    enable = true;
    stateVersion = 5;

    fqdn = "mail.${domain}";
    domains = [ domain ];

    x509.useACMEHost = config.mailserver.fqdn;

    enableImap = true;
    enableSubmission = true;

    # OCI does this
    dkim.enable = false;

    fullTextSearch = {
      enable = true;
      # index new email as they arrive
      autoIndex = true;
      fallback = false;
    };
    enableManageSieve = true;

    mailboxes = {
      Drafts = {
        auto = "subscribe";
        special_use = "\\Drafts";
      };
      Junk = {
        auto = "subscribe";
        fts_autoindex = false;
        special_use = "\\Junk";
      };
      Sent = {
        auto = "subscribe";
        special_use = "\\Sent";
      };
      Archive = {
        auto = "subscribe";
        special_use = "\\Archive";
      };
      Trash = {
        auto = "no";
        fts_autoindex = false;
        special_use = "\\Trash";
      };
    };

    ldap = {
      enable = true;
      uris = [ "ldaps://idm.plamper.org:636" ];
      base = "dc=idm,dc=plamper,dc=org";
      bind = {
        dn = "dn=token";
        passwordFile = config.age.secrets.kanidm-mail-ldap.path;
      };
      attributes = {
        uuid = "uuid";
        mail = "mail";
        username = "mail";
      };
    };
  };

  networking.hosts = {
    "10.20.0.2" = [ "idm.plamper.org" ];
  };

  services.prometheus.exporters.postfix.enable = true;

  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9154 ];

  # OCI email delivery
  services.postfix.settings.main = {
    relayhost = [ "[${ociSmtp}]:587" ];
    smtp_sasl_auth_enable = "yes";
    smtp_sasl_security_options = "noanonymous";
    smtp_sasl_password_maps = "texthash:${config.age.secrets.smtp_pass.path}";
    smtp_tls_security_level = lib.mkForce "encrypt";
    smtp_tls_CAfile = lib.mkDefault "/etc/ssl/certs/ca-certificates.crt";
  };

  # Borg backup for mail storage
  services.borgbackup.jobs.mail = {
    paths = [ config.mailserver.storage.path ];
    repo = "ssh://borg@10.20.0.2/~/mail";
    encryption.mode = "none";
    environment = {
      BORG_RSH = "ssh -i /var/vmail/.ssh/id_ed25519";
    };
    compression = "auto,zstd";
    startAt = "daily";
    persistentTimer = true;
  };

  # Add a masteruser for seamless nextcloud
  services.dovecot2.settings = {
    auth_master_user_separator = "*";
    "passdb dovecot-masteruser" = {
      driver = "passwd-file";
      passwd_file_path = config.age.secrets.dovecot-masteruser.path;
      result_success = "continue";
      master = "yes";
    };
  };

  email-autoconfig = {
    enable = true;
    domain = domain;
    mailDomain = config.mailserver.fqdn;
  };
}
