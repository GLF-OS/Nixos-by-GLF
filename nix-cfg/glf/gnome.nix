{ pkgs, lib, ... }:
{
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Activation de Gnome
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  services = {
    udev.packages = [ pkgs.gnome-settings-daemon ];
    xserver = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };
  };
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Packages système
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  environment.systemPackages = with pkgs;[

    # theme
    adw-gtk3
    graphite-gtk-theme
    tela-circle-icon-theme

    # gnome
    gnome-tweaks
    gnome-software

    # Extension
    gnomeExtensions.caffeine
    gnomeExtensions.gsconnect
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Paquets exclus de l'installation de GNOME
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  environment.gnome.excludePackages = with pkgs; [
    xterm
    gnome-tour
    tali
    iagno
    hitori
    atomix
    yelp
    geary
    xterm
    gnome-user-docs
    epiphany
    gnome-packagekit
    packagekit
    gnome-tour
  ];

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Paramètre GNOME
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
            theme = "adw-gtk3";
            focus-mode = "click";
            visual-bell = false;
          };

          "org/gnome/desktop/interface" = {
            cursor-theme = "Adwaita";
            gtk-theme = "adw-gtk3";
            icon-theme = "Tela-circle";
          };

          "org/gnome/desktop/peripherals/touchpad" = {
            click-method = "areas";
            tap-to-click = true;
            two-finger-scrolling-enabled = true;
          };

          "org/gnome/desktop/peripherals/keyboard" = {
            numlock-state = true;
          };

          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = [
              "caffeine@patapon.info"
              "gsconnect@andyholmes.github.io"
              "appindicatorsupport@rgcjonas.gmail.com"
              "dash-to-dock@micxgx.gmail.com"
            ];
            favorite-apps = [
              "firefox.desktop"
              "steam.desktop"
              "net.lutris.Lutris.desktop"
              "com.heroicgameslauncher.hgl.desktop"
              "discord.desktop"
              "thunderbird.desktop"
              "org.gnome.Nautilus.desktop"
              "org.gnome.Software.desktop"
              "org.gnome.Calendar.desktop"
            ];
          };

          "org/gnome/shell/extensions/dash-to-dock" = {
            click-action = "minimize-or-overview";
            dock-position = "BOTTOM";
            isolate-monitor = false;
            multi-monitor = true;
            show-mounts-network = true;
            always-center-icons = true;
            custom-theme-shrink = true;
          };

          "org/gnome/mutter" = {
            check-alive-timeout = lib.gvariant.mkUint32 30000;
            dynamic-workspaces = true;
            edge-tiling = true;
          };
        };
      }
    ];
  };
}
