{ lib, ... }:
let
  vhostOptions =
    { config, name, ... }:
    let
      baseDomain = lib.concatStringsSep "." (lib.tail (lib.splitString "." name));
      autheliaUrl = "https://auth.${baseDomain}";

      autheliaProtectedConfig = ''
        auth_request /authelia;

        # Modern Nginx Method: Authelia returns the redirect URL in the Location header
        auth_request_set $redirection_url $upstream_http_location;

        auth_request_set $user $upstream_http_remote_user;
        auth_request_set $groups $upstream_http_remote_groups;
        auth_request_set $name $upstream_http_remote_name;

        # Redirect 401s to the URL provided by Authelia
        error_page 401 =302 $redirection_url;
      '';

    in
    {
      options.enableAuthelia = lib.mkEnableOption "Enable Authelia forward-auth on this virtualhost";

      config = lib.mkIf config.enableAuthelia {
        extraConfig = autheliaProtectedConfig;

        locations."/authelia" = {
          recommendedProxySettings = false;
          extraConfig = ''
            internal;

            # FIX: Use the Nginx-specific endpoint
            proxy_pass ${autheliaUrl}/api/authz/auth-request;

            proxy_http_version 1.1;
            proxy_pass_request_body off;
            proxy_set_header Content-Length "";
            proxy_set_header Connection "";

            # Required metadata headers for Authelia's AuthRequest implementation
            proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
            proxy_set_header X-Original-Method $request_method;

            proxy_set_header X-Forwarded-Method $request_method;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $http_host;
            proxy_set_header X-Forwarded-Uri $request_uri;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_ssl_verify on;
            proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
            proxy_ssl_server_name on;
          '';
        };
      };
    };
in
{
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submoduleWith {
        modules = [ vhostOptions ];
        shorthandOnlyDefinesConfig = true;
      }
    );
  };
}
