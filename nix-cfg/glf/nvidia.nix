# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# DO NOT TOUCH
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
{ config, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  nixpkgs.config.nvidia.acceptLicense = true;

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    open = false;

    nvidiaSettings = true;
    modesetting.enable = true;
    dynamicBoost.enable = true;

    powerManagement = {
      enable = true;
    };
  };
}
