{

  description = "GLF-OS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    glf.url     = "github:CORAAL/glf-flake";
  };

  outputs = { self, nixpkgs, glf, ... }@inputs:
  let
    pkgsSettings = system: import nixpkgs { inherit system; config.allowUnfree = true; };
  in {
    nixosConfigurations."GLF-OS" = nixpkgs.lib.nixosSystem {
      pkgs = pkgsSettings "x86_64-linux";
      modules = [
	./configuration.nix
	inputs.glf.nixosModules.default
      ];
    };
  };
  
}
