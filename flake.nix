{
  description = "Espressif ESP32 emulator";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      perSystem = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          espEmu = pkgs.callPackage ./packages/esp-emu { };
          shell = pkgs.mkShell { packages = [ espEmu ]; };
        in
        {
          packages = {
            esp-emu = espEmu;
            default = espEmu;
          };
          devShells = {
            esp-emu = shell;
            default = shell;
          };
          checks.esp-emu = espEmu;
        }
      );
    in
    {
      packages = forAllSystems (system: perSystem.${system}.packages);
      devShells = forAllSystems (system: perSystem.${system}.devShells);
      checks = forAllSystems (system: perSystem.${system}.checks);
    };
}
