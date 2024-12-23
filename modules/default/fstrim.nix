{ lib, config, ... }:

{

  options.glf.fstrim.enable = lib.mkOption {
    description = "Enable GLF Fstrim configurations";
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.glf.fstrim.enable {

    services.fstrim = {
	enable = true;
	interval = "daily";
    };
    
  };

}
