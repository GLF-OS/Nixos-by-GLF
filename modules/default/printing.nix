{ lib, config, pkgs, ... }:

{

  options.glf.printing.enable = lib.mkOption {
    description = "Enable GLF printing configurations";
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.glf.printing.enable {

    boot = {
      tmp.cleanOnBoot = true;
      supportedFilesystems.zfs = lib.mkDefault false;
      kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
      kernelParams = if builtins.elem "kvm-amd" config.boot.kernelModules then [ "amd_pstate=active" ] else [ ];
    };
    
  };

}
