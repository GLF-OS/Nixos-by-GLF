{ pkgs, config, lib, ... }:
{
  boot = {
    tmp.cleanOnBoot = true;
    supportedFilesystems.zfs = lib.mkForce false;

    kernelPackages = pkgs.linuxPackages_latest;
    #linuxPackages_zen 
    #linuxPackages 
    #linuxPackages_latest 
    #linuxPackages_xanmod_latest

    kernel.sysctl = { "vm.max_map_count" = 2147483642; };
    kernelParams = if builtins.elem "kvm-amd" config.boot.kernelModules then [ "amd_pstate=active" ] else [ ];
  };
}
