{
  description = "Nix-Powered NAS";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    agenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pia-nix = {
      url = "github:Atte/pia-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      agenix,
      pia-nix,
      deploy-rs,
      disko,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    {

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        nix-nas = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              outputs
              pia-nix
              agenix
              ;
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/nix-nas
            agenix.nixosModules.default
          ];
        };
      };

      deploy.nodes.nix-nas = {
        hostname = "nix-nas";
        sshUser = "admin";
        interactiveSudo = true;
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nix-nas;
        };
      };

      nixosConfigurations = {
        cloudnix = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              outputs
              pia-nix
              agenix
              ;
          };
          system = "aarch64-linux";
          modules = [
            ./hosts/cloudnix
            agenix.nixosModules.default
            disko.nixosModules.disko
          ];
        };
      };

      deploy.nodes.cloudnix = {
        hostname = "150.230.147.99";
        sshUser = "admin";
        remoteBuild = true;
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.cloudnix;
        };
      };
    };
}
