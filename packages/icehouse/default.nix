{ lib, pkgs, writeShellApplication, substituteAll, ... }:

let
  substitute = args: builtins.readFile (substituteAll args);
in
writeShellApplication {
  name = "icehouse";

  text = substitute {
    src = ./icehouse.sh;

    help = ./help;
  };

  checkPhase = "";

  runtimeInputs = with pkgs; [
    pv
    gum
    zfs
    gnused
    gptfdisk
    util-linux
    cryptsetup
  ];
}
