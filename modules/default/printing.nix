{ lib, config, pkgs, ... }:

{

  options.glf.printing.enable = lib.mkOption {
    description = "Enable GLF printing configurations.";
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.glf.printing.enable (let
    allUsers = builtins.attrNames config.users.users;
    normalUsers = builtins.filter (user: config.users.users.${user}.isNormalUser == true) allUsers;
  in {
    # Configure printer
    services.printing = {
      enable = true;
      startWhenNeeded = true;
      drivers = with pkgs; [
        gutenprint
        hplip
        samsung-unified-linux-driver
        splix
        brlaser
        brgenml1lpr
        cnijfilter2
      ];
    };

    # Enable autodiscovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Scanner support
    hardware.sane = {
      enable = true;
      extraBackends = with pkgs; [ sane-airscan epkowa ];
    };

    # Add all users to group scanner and lp
    users.groups.scanner.members = normalUsers;
    users.groups.lp.members = normalUsers;
  });

}
