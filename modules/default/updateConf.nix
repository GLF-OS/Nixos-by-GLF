{ lib, config, pkgs, ... }:

{
  options.glf.autoUpgrade.enable = lib.mkOption {
    description = "Enable GLF systems configurations auto-upgrade.";
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf config.glf.autoUpgrade.enable {
    let
      updateScript = ''
        #!/bin/bash

        # Répertoire temporaire pour cloner le dépôt
        TMP_DIR=$(mktemp -d)

        # URL du dépôt Git
        REPO_URL="https://github.com/GLF-OS/Nixos-by-GLF.git"

        # Branche et chemin à extraire
        BRANCH="main"
        SUBDIR="nix-cfg/glf"

        # Répertoire cible
        TARGET_DIR="/etc/nixos/glf"

        # Clone le dépôt
        git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"

        # Synchronise le sous-répertoire spécifique
        rsync -a --delete "$TMP_DIR/$SUBDIR/" "$TARGET_DIR/"

        # Nettoyage
        rm -rf "$TMP_DIR"

        echo "Mise à jour terminée à $(date)" >> /var/log/update-glf-config.log
      '';
    in {
      # Ajouter le script à /usr/local/bin
      environment.etc."update-glf-config.sh".text = updateScript;

      # Service pour exécuter le script
      systemd.services.update-glf-config = {
        description = "Update GLF module from git";
        serviceConfig = {
          ExecStart = "${pkgs.bash}/bin/bash /etc/update-glf-config.sh";
        };
        wantedBy = [ "multi-user.target" ];
      };

      # Timer pour planifier les mises à jour
      systemd.timers.update-glf-config = {
        description = "Schedule GLF module updates";
        timerConfig = {
          OnBootSec = "10min";
          OnUnitActiveSec = "3d";
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      # Paquets nécessaires pour le script
      environment.systemPackages = with pkgs; [ git rsync ];
    };
  };
}
