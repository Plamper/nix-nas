{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "plamper.org";
  mailDomain = "mail.${domain}";

  # ---- Thunderbird autoconfig XML ----------------------------------------
  autoconfigXml = pkgs.writeText "autoconfig.xml" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <clientConfig version="1.1">
      <emailProvider id="${domain}">
        <domain>${domain}</domain>
        <displayName>Plamper.org Email</displayName>
        <displayShortName>Plamper.org</displayShortName>

        <incomingServer type="imap">
          <hostname>${mailDomain}</hostname>
          <port>993</port>
          <socketType>SSL</socketType>
          <authentication>password-cleartext</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>

        <outgoingServer type="smtp">
          <hostname>${mailDomain}</hostname>
          <port>465</port>
          <socketType>SSL</socketType>
          <authentication>password-cleartext</authentication>
          <username>%EMAILADDRESS%</username>
        </outgoingServer>
      </emailProvider>

      <addressBook type="carddav">
        <hostname>cloud.${domain}</hostname>
        <port>443</port>
        <socketType>SSL</socketType>
        <username>%EMAILLOCALPART%</username>
        <serverURL>https://cloud.${domain}/remote.php/dav/</serverURL>
      </addressBook>

      <calendar type="caldav">
        <hostname>cloud.${domain}</hostname>
        <port>443</port>
        <socketType>SSL</socketType>
        <username>%EMAILLOCALPART%</username>
        <serverURL>https://cloud.${domain}/remote.php/dav/</serverURL>
      </calendar>
    </clientConfig>
  '';

  # ---- Outlook Autodiscover XML ------------------------------------------
  autodiscoverXml = pkgs.writeText "autodiscover.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
      <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
        <Account>
          <AccountType>email</AccountType>
          <Action>settings</Action>
          <Protocol>
            <Type>IMAP</Type>
            <Server>${mailDomain}</Server>
            <Port>993</Port>
            <LoginName/>
            <DomainRequired>off</DomainRequired>
            <SPA>off</SPA>
            <SSL>on</SSL>
            <AuthRequired>on</AuthRequired>
          </Protocol>
          <Protocol>
            <Type>SMTP</Type>
            <Server>${mailDomain}</Server>
            <Port>465</Port>
            <LoginName/>
            <DomainRequired>off</DomainRequired>
            <SPA>off</SPA>
            <SSL>on</SSL>
            <AuthRequired>on</AuthRequired>
            <UsePOPAuth>off</UsePOPAuth>
            <SMTPLast>off</SMTPLast>
          </Protocol>
          <Protocol>
            <Type>DAV</Type>
            <Server>https://cloud.${domain}/remote.php/dav/</Server>
            <SSL>on</SSL>
            <AuthRequired>on</AuthRequired>
          </Protocol>
        </Account>
      </Response>
    </Autodiscover>
  '';

  # ---- Apple Mail .mobileconfig ------------------------------------------
  # Sign this with your CA in production; unsigned works but warns on iOS/macOS.
  mobileconfigContent = pkgs.writeText "profile.mobileconfig" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>PayloadContent</key>
      <array>
        <dict>
          <key>EmailAccountDescription</key>
          <string>Plamper.org Mail</string>
          <key>EmailAccountName</key>
          <string>Plamper.org</string>
          <key>EmailAccountType</key>
          <string>EmailTypeIMAP</string>
          <key>EmailAddress</key>
          <string/>
          <key>IncomingMailServerHostName</key>
          <string>${mailDomain}</string>
          <key>IncomingMailServerPortNumber</key>
          <integer>993</integer>
          <key>IncomingMailServerUseSSL</key>
          <true/>
          <key>IncomingMailServerUsername</key>
          <string/>
          <key>OutgoingMailServerHostName</key>
          <string>${mailDomain}</string>
          <key>OutgoingMailServerPortNumber</key>
          <integer>465</integer>
          <key>OutgoingMailServerUseSSL</key>
          <true/>
          <key>OutgoingMailServerUsername</key>
          <string/>
          <key>PayloadDescription</key>
          <string>Email account settings</string>
          <key>PayloadDisplayName</key>
          <string>Plamper.org Mail</string>
          <key>PayloadIdentifier</key>
          <string>com.${domain}.mail</string>
          <key>PayloadType</key>
          <string>com.apple.mail.managed</string>
          <key>PayloadUUID</key>
          <string>A1B2C3D4-E5F6-7890-ABCD-EF1234567890</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>SMIMEEnabled</key>
          <false/>
        </dict>

        <dict>
          <key>PayloadType</key>
          <string>com.apple.carddav.account</string>
          <key>PayloadIdentifier</key>
          <string>com.${domain}.carddav</string>
          <key>PayloadUUID</key>
          <string>C3D4E5F6-A7B8-9012-CDEF-123456789012</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadDisplayName</key>
          <string>Plamper.org Contacts</string>
          <key>CardDAVAccountDescription</key>
          <string>Plamper.org Contacts</string>
          <key>CardDAVHostName</key>
          <string>cloud.${domain}</string>
          <key>CardDAVPort</key>
          <integer>443</integer>
          <key>CardDAVPrincipalURL</key>
          <string>https://cloud.${domain}/.well-known/carddav</string>
          <key>CardDAVUseSSL</key>
          <true/>
          <key>CardDAVUsername</key>
          <string/>
        </dict>

        <dict>
          <key>PayloadType</key>
          <string>com.apple.caldav.account</string>
          <key>PayloadIdentifier</key>
          <string>com.${domain}.caldav</string>
          <key>PayloadUUID</key>
          <string>D4E5F6A7-B8C9-0123-DEFF-234567890123</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadDisplayName</key>
          <string>Plamper.org Calendar</string>
          <key>CalDAVAccountDescription</key>
          <string>Plamper.org Calendar</string>
          <key>CalDAVHostName</key>
          <string>cloud.${domain}</string>
          <key>CalDAVPort</key>
          <integer>443</integer>
          <key>CalDAVPrincipalURL</key>
          <string>https://cloud.${domain}/.well-known/caldav</string>
          <key>CalDAVUseSSL</key>
          <true/>
          <key>CalDAVUsername</key>
          <string/>
        </dict>

      </array>
      <key>PayloadDescription</key>
      <string>Configures email, contacts and calendar for ${domain}</string>
      <key>PayloadDisplayName</key>
      <string>Plamper.org Mail</string>
      <key>PayloadIdentifier</key>
      <string>com.${domain}.mail.profile</string>
      <key>PayloadOrganization</key>
      <string>Plamper Org</string>
      <key>PayloadRemovalDisallowed</key>
      <false/>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>B2C3D4E5-F6A7-8901-BCDE-F12345678901</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
    </dict>
    </plist>
  '';

  # ---- Static webroot -------------------------------------------------------
  # All config files assembled into a directory tree nginx can serve with
  # root, avoiding the alias path-traversal issue entirely.
  mailConfigRoot = pkgs.runCommand "mail-config-root" { } ''
    mkdir -p $out/mail
    mkdir -p $out/Autodiscover
    mkdir -p $out/autodiscover

    cp ${autoconfigXml}       $out/mail/config-v1.1.xml
    cp ${autodiscoverXml}     $out/Autodiscover/Autodiscover.xml
    cp ${autodiscoverXml}     $out/autodiscover/autodiscover.xml
    cp ${mobileconfigContent} $out/mobileconfig
  '';

in
{
  services.nginx = {
    enable = true;

    virtualHosts = {

      # ---- autoconfig.plamper.org — Thunderbird ----------------------------
      # Thunderbird fetches:
      #   https://autoconfig.${domain}/mail/config-v1.1.xml
      "autoconfig.${domain}" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        root = "${mailConfigRoot}";

        locations."/mail/config-v1.1.xml" = {
          extraConfig = ''
            default_type application/xml;
            add_header Content-Disposition 'inline; filename="config-v1.1.xml"';
            add_header Access-Control-Allow-Origin "*";
          '';
        };
      };

      # ---- autodiscover.plamper.org — Outlook ------------------------------
      # Outlook fetches (GET and POST):
      #   https://autodiscover.${domain}/Autodiscover/Autodiscover.xml
      # DNS SRV record required:
      #   _autodiscover._tcp.${domain}  SRV  0 0 443  autodiscover.${domain}.
      "autodiscover.${domain}" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        root = "${mailConfigRoot}";

        locations."/Autodiscover/Autodiscover.xml" = {
          extraConfig = ''
            default_type application/xml;
            add_header Access-Control-Allow-Origin "*";
          '';
        };

        # Case-insensitive catch-all — Outlook varies capitalisation
        locations."~* ^/autodiscover/autodiscover\\.xml$" = {
          extraConfig = ''
            default_type application/xml;
            add_header Access-Control-Allow-Origin "*";
          '';
        };
      };

      # ---- mail.plamper.org — Apple mobileconfig ---------------------------
      # iOS/macOS fetches the profile from here.
      # Serve on the mail subdomain so ACME is already handled by your
      # mail server vhost — add this locations block there if you have one,
      # or keep it as a standalone vhost if mail.${domain} is proxied elsewhere.
      "mail.${domain}" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        root = "${mailConfigRoot}";

        locations."/mobileconfig" = {
          extraConfig = ''
            default_type application/x-apple-aspen-config;
            add_header Content-Disposition 'attachment; filename="mail.mobileconfig"';
          '';
        };
      };

    };
  };
}
