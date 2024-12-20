{

  description = "GLF-OS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    glf.url     = "github:CORAAL/Nixos-by-GLF";
  };

  outputs = { self, nixpkgs, glf, ... }@inputs:
  let
    pkgsSettings = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      nix.settings.experimental-features = [ "nix-command" "flakes" ];
};
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
