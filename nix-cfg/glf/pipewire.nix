{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;

    jack.enable = true;
    pulse.enable = true;

    alsa = {
      enable = true;
      support32Bit = true;
    };

    wireplumber.extraConfig = {
      "10-disable-camera" = {
        "wireplumber.profiles" = {
          main = {
            "monitor.libcamera" = "disabled";
          };
        };
      };
    };
  };
}
