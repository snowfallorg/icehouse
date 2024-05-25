{
  description = "Snowfall Ice House";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";

    snowfall-lib = {
      url = "github:snowfallorg/lib?ref=v3.0.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      alias.packages.default = "icehouse";

      snowfall = {
        namespace = "snowfallorg";
      };
    };
}
