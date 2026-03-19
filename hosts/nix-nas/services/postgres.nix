{ pkgs, ... }:
{

  # Setup Postgres
  services.postgresql = {
    enable = true;

    # Copied from wiki to fix postgres login
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method optional_ident_map
      local sameuser  all     peer        map=superuser_map
    '';
    identMap = ''
      # ArbitraryMapName systemUser DBUser
         superuser_map      root      postgres
         # Let other names login as themselves
         superuser_map      /^(.*)$   \1
    '';
  };
}
