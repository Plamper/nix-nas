{ pkgs, ... }:
{
  # Setup Postgres
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;

    # Fix collation mismatches
    initdbArgs = [
      "--locale-provider=builtin"
      "--builtin-locale=C.UTF-8"
    ];
    # Copied from wiki to fix postgres login, extended so the postgres
    # superuser can connect to any database (not just one matching its name)
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser    auth-method optional_ident_map
      local all        postgres peer        map=superuser_map
      local sameuser   all      peer        map=superuser_map
    '';
    identMap = ''
      # ArbitraryMapName systemUser DBUser
         superuser_map      root      postgres
         # Let other names login as themselves
         superuser_map      /^(.*)$   \1
    '';
  };

  users.users.postgres.extraGroups = [ "backup" ];

  services.postgresqlBackup = {
    enable = true;
    databases = [
      "vaultwarden"
      "forgejo"
    ];
    location = "/mnt/data-pool/Backups/postgres";
    compression = "zstd";
    startAt = "*-*-* 02:00:00";
  };
}
