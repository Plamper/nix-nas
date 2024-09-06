{
  description = "Nix-Powered NAS";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pia-nix = {
      url = "github:Atte/pia-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , agenix
    , pia-nix
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        nix-nas = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs pia-nix agenix; };
          modules = [
            ./configuration.nix
            agenix.nixosModules.default
          ];
        };
      };
    };
}
