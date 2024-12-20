{

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  nix = {
    optimise = {
      automatic = true;
      dates = [ "daily" ];
    };

    settings = {
      auto-optimise-store = true;
    };
  };

}
