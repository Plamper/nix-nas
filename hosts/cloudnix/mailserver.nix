{ config, pkgs, ... }:

let
  domain  = "plamper.org";
  ociSmtp = "smtp.email.eu-frankfurt-1.oci.oraclecloud.com"; # adjust region
  mailDir = "/var/vmail";

  lldap = {
    host         = "10.20.0.2";
    port         = 3890;                    
    baseDn       = "dc=plamper,dc=org";
    bindDn       = "uid=admin,ou=people,dc=plamper,dc=org";
  };
in
{

  age.secrets = {
    lldap_user_pass = {
      file = ../../secrets/lldap_user_pass.age;
      group = "certs";
    };
    postfix-sasl-passwd = {
      file = ../../secrets/postfix-sasl-passwd.age;
      group = "certs";
    };
  };

  # Virtual mailbox user (owns maildirs on disk)
  users.users.vmail = {
    isSystemUser = true;
    group        = "vmail";
    home         = mailDir;
    createHome   = true;
  };
  users.groups.vmail = {};
  users.users.dovecot2.extraGroups = [ "certs" ];
  users.users.postfix.extraGroups  = [ "certs" ];


  # Dovecot — IMAP server + auth backend for Postfix
  services.dovecot2 = {
    enable     = true;
    enableImap = true;
    enableLmtp = true;   # Postfix delivers to Dovecot via LMTP
    enablePAM = false; # only use lldap

    mailUser  = "vmail";
    mailGroup = "vmail";

    # Maildir layout: /var/mail/vmail/plamper.org/username/
    mailLocation = "maildir:${mailDir}/%d/%n";

    sslServerCert = "/var/lib/acme/mail.${domain}/cert.pem";
    sslServerKey  = "/var/lib/acme/mail.${domain}/key.pem";

    extraConfig = ''
      # ── Auth via LLDAP ──────────────────────────────────────
      passdb {
        driver = ldap
        args   = /etc/dovecot/ldap.conf
      }

      userdb {
        driver = static
        args   = uid=vmail gid=vmail home=${mailDir}/%d/%n
      }

      # ── Expose auth socket for Postfix SASL ─────────────────
      service auth {
        unix_listener /var/lib/postfix/queue/private/auth {
          mode  = 0660
          user  = postfix
          group = postfix
        }
      }

      # ── LMTP socket for Postfix delivery ────────────────────
      service lmtp {
        unix_listener /var/lib/postfix/queue/private/dovecot-lmtp {
          mode  = 0600
          user  = postfix
          group = postfix
        }
      }

      # ── Standard mailbox folders ─────────────────────────────
       namespace inbox {
        inbox = yes
        mailbox Drafts {
          special_use = \Drafts
          auto = subscribe
        }
        mailbox Sent {
          special_use = \Sent
          auto = subscribe
        }
        mailbox Trash {
          special_use = \Trash
          auto = subscribe
        }
        mailbox Junk {
          special_use = \Junk
          auto = subscribe
        }
      }
    '';
  };

  # Dovecot LDAP config (separate file — contains path to bind password)
  system.activationScripts."dovecot-ldap-conf" = {
    deps = [ "agenix" ];  # ensure secrets are decrypted first
    text = ''
        secret=$(cat "${config.age.secrets.lldap_user_pass.path}")
        install -m 0640 -o root -g vmail /dev/null /etc/dovecot/ldap.conf
        cat > /etc/dovecot/ldap.conf <<EOF
        hosts=${lldap.host}:${toString lldap.port}
        dn=${lldap.bindDn}
        dnpass=$secret
        base=ou=people,${lldap.baseDn}
        scope=subtree
        auth_bind=yes
        pass_filter=(&(objectClass=person)(mailboxAddress=%u))
        pass_attrs=mailboxAddress=user
        user_attrs=mailboxAddress=user
        EOF
      '';
  };


  # Postfix — receive (port 25) + submission (port 587) + OCI relay
  services.postfix = {
    enable   = true;

    # actually send emails
    enableSubmissions = true;
    submissionsOptions = {
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "private/auth";
      smtpd_client_restrictions = "permit_sasl_authenticated,reject";
      milter_macro_daemon_name = "ORIGINATING";
    };

    settings.main = {
      mydestination = [ "localhost" ];
      myorigin   = domain;
      mydomain   = domain;
      myhostname = "mail.${domain}";

      virtual_mailbox_domains    = domain;
      virtual_transport          = "lmtp:unix:private/dovecot-lmtp";

      virtual_mailbox_maps       = "ldap:/var/lib/postfix/conf/ldap-recipients.cf";

      smtpd_sasl_type             = "dovecot";
      smtpd_sasl_path             = "private/auth";
      smtpd_sasl_auth_enable      = "yes";
      smtpd_sasl_security_options = "noanonymous";
      smtpd_recipient_restrictions = "permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination";

      smtpd_tls_cert_file      = "/var/lib/acme/mail.${domain}/cert.pem";
      smtpd_tls_key_file       = "/var/lib/acme/mail.${domain}/key.pem";
      smtpd_tls_security_level = "may";

      relayhost                  = [ "[${ociSmtp}]:587" ];
      smtp_sasl_auth_enable      = "yes";
      smtp_sasl_security_options = "noanonymous";
      smtp_sasl_password_maps    = "texthash:${config.age.secrets.postfix-sasl-passwd.path}";
      smtp_tls_security_level    = "encrypt";
      smtp_tls_CAfile            = "/etc/ssl/certs/ca-certificates.crt";
    };
  };

  systemd.services.postfix.serviceConfig.ExecStartPre = let
    script = pkgs.writeShellScript "postfix-ldap-setup" ''
      secret=$(cat "${config.age.secrets.lldap_user_pass.path}" | tr -d '\n')
      mkdir -p /var/lib/postfix/conf
      install -m 0640 -o root -g postfix /dev/null /var/lib/postfix/conf/ldap-recipients.cf
      cat > /var/lib/postfix/conf/ldap-recipients.cf <<HEREDOC
      server_host=${lldap.host}
      server_port=${toString lldap.port}
      version=3
      bind=yes
      bind_dn=${lldap.bindDn}
      bind_pw=$secret
      search_base=ou=people,${lldap.baseDn}
      scope=sub
      query_filter=(&(objectClass=person)(mailboxAddress=%s))
      result_attribute=mailboxAddress
      HEREDOC
        '';
  in [ "+${script}" ];

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

  services.nginx = {
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    enable = true;
    virtualHosts."autoconfig.plamper.org" = {
      enableACME = true;
      forceSSL = true;
      acmeRoot = null;
    };
  };

  networking.firewall.allowedTCPPorts = [ 25 443 465 993 ];
}
