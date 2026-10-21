# esp-emu.nix

Standalone flake for the [Espressif ESP32 emulator](https://github.com/espressif/esp-emulator).

## Packages

- `esp-emu`: packages the upstream prebuilt `esp-emu`
- `default`: alias of `esp-emu`

## Usage

Build examples

```sh
nix build .#esp-emu
nix build .#default
```

Run examples

```sh
nix run github:Sped0n/esp-emu.nix#esp-emu -- --help
```

Shell examples

```sh
nix shell github:Sped0n/esp-emu.nix#esp-emu
nix develop .#esp-emu
```

`nix-direnv` example

```sh
use flake github:Sped0n/esp-emu.nix#esp-emu
```

Flake example

```nix
inputs.esp-emu.url = "github:Sped0n/esp-emu.nix";

home.packages = [
  inputs.esp-emu.packages.${pkgs.system}.esp-emu
];
```
