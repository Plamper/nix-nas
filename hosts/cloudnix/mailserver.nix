{ inputs, config, lib, pkgs, ... }:

let
  domain = "plamper.org";
  ociSmtp = "smtp.email.eu-frankfurt-1.oci.oraclecloud.com";
in
{
  imports = [
    inputs.snm.nixosModules.default
  ];

  age.secrets = {
    lldap_pass.file = ../../secrets/lldap_user_pass.age;
    dovecot-masteruser.file = ../../secrets/dovecot-masterpassword.age;
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
    stateVersion = 3;

    fqdn = "mail.${domain}";
    domains = [ domain ];

    certificateScheme = "acme";

    enableImap = true;
    enableSubmission = true;

    # OCI does this
    dkimSigning = false;

    fullTextSearch.enable = true;
    enableManageSieve = true;

    ldap = {
      enable = true;

      uris = [ "ldap://10.20.0.2:3890" ];
      searchBase = "ou=people,dc=plamper,dc=org";

      bind = {
        dn = "uid=admin,ou=people,dc=plamper,dc=org";
        passwordFile = config.age.secrets.lldap_pass.path;
      };

      dovecot = {
        passFilter = "(&(objectClass=person)(mailboxAddress=%{user}))";
        passAttrs = "userPassword=password";
        userFilter = "(&(objectClass=person)(mailboxAddress=%{user}))";
        userAttrs = null;
      };

      postfix = {
        filter = "(&(objectClass=person)(mailboxAddress=%s))";
        mailAttribute = "mailboxAddress";
        uidAttribute = "mailboxAddress";
      };
    };
  };

  # OCI email delivery
  services.postfix.settings.main = {
    relayhost                  = [ "[${ociSmtp}]:587" ];
    smtp_sasl_auth_enable      = "yes";
    smtp_sasl_security_options = "noanonymous";
    smtp_sasl_password_maps    = "texthash:${config.age.secrets.smtp_pass.path}";
    smtp_tls_security_level    = lib.mkForce "encrypt";
    smtp_tls_CAfile            = "/etc/ssl/certs/ca-certificates.crt";
  };

  # Add a masteruser for seemless nextcloud
  services.dovecot2.extraConfig = ''
    auth_master_user_separator = *
    passdb {
      driver = passwd-file
      args = ${config.age.secrets.dovecot-masteruser.path}
      master = yes
      pass = yes
    }
  '';

  # autodiscovery via thunderbird
  services.automx2 = {
    enable = true;
    domain = "plamper.org"; 
    settings = {
      version = 2;
      provider = "plamper.org";
      servers = [
        {
          type = "imap";
          port = 993;
          name = "mail.plamper.org";
          socket = "SSL";
          authentication = "plain";
        }
        {
          type = "smtp";
          port = 465;
          name = "mail.plamper.org";
          socket = "SSL";
          authentication = "plain";
        }
      ];
      domains = [ "plamper.org" ];
    };
  };

  # Cloudflare setup
  # autoconfig.plamper.org    A      <your server IP>
  # autodiscover.plamper.org  CNAME  autoconfig.plamper.org

  services.nginx.virtualHosts."autoconfig.plamper.org" = {
    enableACME = true;
    forceSSL = true;
    acmeRoot = null;
  };

  networking.firewall.allowedTCPPorts = [ 25 465 993 ];
}
