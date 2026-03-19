{ config, lib, ... }:

let
  vhostOptions = {config,...}: {
    options = {
      enableAuthelia = lib.mkEnableOption "Enable authelia location";
    };
    config =
      lib.mkIf config.enableAuthelia {
        locations."/authelia".extraConfig = ''
          PUT WHATEVER CONFIGURATION YOU WANT, HERE
        '';
      };
  };
in
{
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule vhostOptions);
  };
}
