{ config, ... }:
{
  # Configure ACME appropriately
  security.acme.acceptTerms = true;
  security.acme.defaults = {
    email = "felix.plamper@tuta.io";
    dnsResolver = "1.1.1.1:53";
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets."cloudflare-token".path;
    extraLegoFlags = [ "--dns.propagation-wait=15s" ]; # Dns Propagation check does not work
  };
  
  users.groups.certs = {};
  security.acme.certs."mail.plamper.org" = {
    domain = "mail.plamper.org";
    group  = "certs";
  };
}

