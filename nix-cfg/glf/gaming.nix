{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    heroic
    lutris
    goverlay
    mangohud
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    MANGOHUD_CONFIG = "horizontal,hud_no_margin,cpu_stats,ram,gpu_name,gpu_stats,vram,fps,frametime=0,frame_timing=0,time,time_format=%H\\:%M";
  };

  services.udev.extraRules = ''
    # USB
    ATTRS{name}=="Sony Interactive Entertainment Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    ATTRS{name}=="Sony Interactive Entertainment DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    # Bluetooth
    ATTRS{name}=="Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    ATTRS{name}=="DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

  hardware.steam-hardware.enable = true;

  programs = {
    steam = {
      enable = true;
      package = pkgs.steam.override { extraEnv = { MANGOHUD = true; OBS_VKCAPTURE = true; }; };
      extest.enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
    };
  };
}
