{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{

  # Stuff thats should be present on all hosts

  environment.systemPackages = (
    with pkgs;
    [
      git
      nixd
      nixpkgs-fmt
      dig
      helix
      lazygit
      ragenix
    ]
  );

  time.timeZone = lib.mkDefault "Europe/Berlin";

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";
        # Opinionated: disable global registry
        flake-registry = "";
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;

        trusted-users = [ "@wheel" ];
      };
      # Opinionated: disable channels
      channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

}
