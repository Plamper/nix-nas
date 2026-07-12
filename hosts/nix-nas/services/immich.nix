{
  config,
  ...
}:
{

  # Immich photo backup service with OIDC authentication via Authelia
  services.immich = {
    enable = true;
    mediaLocation = "/mnt/data-pool/immich";
    host = "0.0.0.0";
    port = 2283;
    openFirewall = false; # Firewall handled by reverse proxy

    # Database configuration
    database = {
      enable = true;
      createDB = true;
    };

    # Redis cache for performance
    redis = {
      enable = true;
    };

    # Machine learning for face detection and object recognition
    machine-learning = {
      enable = true;
    };
  };

  # Ensure PostgreSQL is available for Immich
  services.postgresql = {
    enable = true;
  };

  # OAuth secret for Immich
  age.secrets = {
    immich-oauth-secret = {
      file = ../../../secrets/immich-oauth-secret.age;
      owner = "immich";
      group = "immich";
      mode = "0400";
    };
  };

}
