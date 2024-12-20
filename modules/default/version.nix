{ lib, config, pkgs, ... }:

{
  options.glf.version.enable = lib.mkOption {
    description = "Enable GLF version configurations.";
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.glf.version.enable {
    let
      # Variables définissant le système
      DISTRO_NAME = "GLF-OS";
      DISTRO_ID = "glfos";

      cfg = config.system.nixos;

      # Fonction pour échapper les caractères spéciaux
      needsEscaping = s: null != builtins.match "[^a-zA-Z0-9]+" s;
      escapeIfNecessary = s: if needsEscaping s then ''"${builtins.replaceStrings ["\\" "\`" "\"" "\$"] [ "\\\\" "\\`" "\\\"" "\\$" ] s}"'' else s;

      # Convertit des attributs en format texte
      attrsToText = attrs:
        let
          attrStrings = mapAttrsToList (n: v: ''${n}=${escapeIfNecessary (toString v)}'') attrs;
        in
          builtins.concatStrings "\n" attrStrings + "\n";

      # Contenu des fichiers os-release et lsb-release
      osReleaseContents = {
        NAME = DISTRO_NAME;
        ID = DISTRO_ID;
        VERSION = "${cfg.release} (${cfg.codeName})";
        VERSION_CODENAME = builtins.toLower cfg.codeName;
        VERSION_ID = cfg.release;
        BUILD_ID = cfg.version;
        PRETTY_NAME = "${DISTRO_NAME} ${cfg.release} (${cfg.codeName})";
        # LOGO = "glfos-logo"; # À activer si besoin
        # HOME_URL = "https://glfos.org"; # À activer si besoin
        DOCUMENTATION_URL = "";
        SUPPORT_URL = "";
        BUG_REPORT_URL = "";
      };

      # Contenu spécifique pour l'initrd
      initrdReleaseContents = osReleaseContents // {
        PRETTY_NAME = "${osReleaseContents.PRETTY_NAME} (Initrd)";
      };

      initrdRelease = pkgs.writeText "initrd-release" (attrsToText initrdReleaseContents);
    in {
      # Fichiers os-release et lsb-release
      environment.etc."os-release".text = lib.mkForce (attrsToText osReleaseContents);
      environment.etc."lsb-release".text = lib.mkForce (attrsToText {
        LSB_VERSION = "${cfg.release} (${cfg.codeName})";
        DISTRIB_ID = DISTRO_ID;
        DISTRIB_RELEASE = cfg.release;
        DISTRIB_CODENAME = builtins.toLower cfg.codeName;
        DISTRIB_DESCRIPTION = "${DISTRO_NAME} ${cfg.release} (${cfg.codeName})";
      });

      # Configuration pour l'initrd
      boot.initrd.systemd.contents."/etc/os-release".source = lib.mkForce initrdRelease;
      boot.initrd.systemd.contents."/etc/initrd-release".source = lib.mkForce initrdRelease;

      # Configuration spécifique au système
      system.nixos.distroName = DISTRO_NAME;
      system.nixos.distroId = DISTRO_ID;
    };
  };
}
