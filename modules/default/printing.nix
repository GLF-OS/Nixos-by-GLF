{ lib, config, pkgs, ... }:

{
  options.glf.printing.enable = lib.mkOption {
    description = "Enable GLF printing configurations.";
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.glf.printing.enable (let
    # Calcul des utilisateurs normaux
    allUsers = builtins.attrNames config.users.users;
    normalUsers = builtins.filter (user: config.users.users.${user}.isNormalUser == true) allUsers;
  in {
    # Configuration de l'impression
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

    # Activation de la découverte automatique
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Support des scanners
    hardware.sane = {
      enable = true;
      extraBackends = with pkgs; [ sane-airscan epkowa ];
    };

    # Ajout des utilisateurs normaux aux groupes scanner et lp
    users.groups.scanner.members = normalUsers;
    users.groups.lp.members = normalUsers;
  });
}
