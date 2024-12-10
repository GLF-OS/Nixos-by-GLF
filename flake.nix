{
  inputs = { nixpkgs.url = "nixpkgs/nixos-24.11"; };

  outputs = { nixpkgs, ... } @ inputs:
    let system = "x86_64-linux";
    in
    rec
    {
      iso = nixosConfigurations."glf-installer".config.system.build.isoImage;

      nixosConfigurations = {
        "glf-installer" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; }; inherit system;

          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
            ./nix-cfg/configuration.nix
            {
              nixpkgs.overlays = [
                (self: super: {
                  calamares-nixos-extensions = super.calamares-nixos-extensions.overrideAttrs (oldAttrs: {
                    postInstall = ''
                      cp ${./patches/calamares-nixos-extensions/modules/nixos/main.py}                   $out/lib/calamares/modules/nixos/main.py
                      cp -r ${./patches/calamares-nixos-extensions/config/settings.conf}                 $out/share/calamares/settings.conf
                      cp -r ${./patches/calamares-nixos-extensions/config/modules/packagechooser.conf}   $out/share/calamares/modules/packagechooser.conf
                      
                      cp -r ${./patches/calamares-nixos-extensions/branding/nixos/show.qml}        $out/share/calamares/branding/nixos/show.qml
                      cp -r ${./patches/calamares-nixos-extensions/branding/nixos/white.png}       $out/share/calamares/branding/nixos/white.png
                      cp -r ${./patches/calamares-nixos-extensions/branding/nixos/base.png}        $out/share/calamares/branding/nixos/base.png
                      cp -r ${./patches/calamares-nixos-extensions/branding/nixos/fast.png}        $out/share/calamares/branding/nixos/fast.png
                      cp -r ${./patches/calamares-nixos-extensions/branding/nixos/gaming.png}      $out/share/calamares/branding/nixos/gaming.png
                      cp -r ${./patches/calamares-nixos-extensions/branding/nixos/logo-glf-os.svg} $out/share/calamares/branding/nixos/logo-glf-os.svg
                      cp -r ${./patches/calamares-nixos-extensions/branding/nixos/branding.desc}   $out/share/calamares/branding/nixos/branding.desc
                    '';
                  });
                })
              ];
            }
            ({ config, ... }: {
              isoImage = {
                volumeID = nixpkgs.lib.mkDefault "GLF-OS_${config.system.nixos.version}";

                includeSystemBuildDependencies = false;
                storeContents = [ config.system.build.toplevel ];
                squashfsCompression = "zstd -Xcompression-level 22";
                contents = [{
                  source = ./nix-cfg;
                  target = "/nix-cfg";
                }];
              };
            })
          ];
        };
      };
    };
}
