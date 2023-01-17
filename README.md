# Ice House

<a href="https://nixos.wiki/wiki/Flakes" target="_blank">
	<img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge">
</a>
<a href="https://github.com/snowfallorg/lib" target="_blank">
	<img alt="Built With Snowfall" src="https://img.shields.io/static/v1?label=Built%20With&labelColor=5e81ac&message=Snowfall&color=d8dee9&style=for-the-badge">
</a>

<p>
<!--
	This paragraph is not empty, it contains an em space (UTF-8 8195) on the next line in order
	to create a gap in the page.
-->
  
</p>

> Cold storage made easy.

> **Note**
>
> Ice House requires ZFS support to function properly.

## Try Without Installing

You can try Ice House without committing to installing it on your system by running the following command.

```bash
nix run github:snowfallorg/icehouse
```

## Install Ice House

### Nix Profile

You can install this package imperatively with the following command.

```bash
nix profile install github:snowfallorg/icehouse
```

## Nix Configuration

You can install this package by adding it as an input to your Nix flake.

```nix
{
	description = "My system flake";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";

		# Snowfall Lib is not required, but will make configuration easier for you.
		snowfall-lib = {
			url = "github:snowfallorg/lib";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		icehouse = {
			url = "github:snowfallorg/icehouse";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs:
		inputs.snowfall-lib.mkFlake {
			inherit inputs;
			src = ./.;

			overlays = with inputs; [
				# Use the overlay provided by this flake.
				icehouse.overlay

				# There is also a named overlay, though the output is the same.
				icehouse.overlays."package/icehouse"
			];
		};
}
```

If you've added the overlay from this flake, then in your system configuration you can add the `snowfallorg.icehouse` package.

```bash
{ pkgs }:

{
	environment.systemPackages = with pkgs; [
		snowfallorg.icehouse
	];
}
```
