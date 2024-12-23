{ lib, config, ... }:

{

  options.glf.nh.enable = lib.mkOption {
    description = "Enable GLF nh configurations";
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.glf.nh.enable {

    environment.shellAliases = { rebuild = "nh os switch /etc/nixos"; };

    programs.nh = {
      enable = true;
      clean = {
	enable = true;
	dates = "weekly";
	extraArgs = "--keep-since 7d --keep 3";
      };
    };

  };

}
