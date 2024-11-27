{
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # DO NOT TOUCH
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  system.autoUpgrade = { enable = true; dates = "weekly"; };

  nixpkgs = { config = { allowUnfree = true; }; };

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
