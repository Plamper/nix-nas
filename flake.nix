{
  description = "Nix-Powered NAS";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    agenix = {
      url = "github:ryantm/agenix";
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

    dyn-channels = {
      url = "github:Plamper/Dynamic-Voice-Channels";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snm = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    email-autoconfig = {
      url = "github:plamper/nixos-email-autoconfig";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      agenix,
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

      devShell = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nix
            agenix.packages.${system}.default
            nixd
            nixfmt-rfc-style
            git
            wireguard-tools
            deploy-rs.packages.${system}.default
            qrencode
          ];
        }
      );

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        nix-nas = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              outputs
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
