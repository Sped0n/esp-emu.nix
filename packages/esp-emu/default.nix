{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:
let
  sources = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-PziPRK446CnHTWN6aPTYChNsN1/019ForPh8jSdPAHU=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-ol8EA0jBcoaIXU6EzY8Gke1XLqwfNCjYjCgU/pMMg+U=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-Myi0zOnjM4oOo0dn2x8v3ZomSxJkNN/sFqAgkeGUnrg=";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "esp-emu is unsupported on ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "esp-emu";
  version = "0.50.0";

  src = fetchurl {
    url = "https://github.com/espressif/esp-emulator/releases/download/v${finalAttrs.version}/esp-emu-${finalAttrs.version}-${source.target}.tar.gz";
    inherit (source) hash;
  };

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;
  # Preserve the upstream binaries, including the macOS code signature.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 esp-emu "$out/bin/esp-emu"
    runHook postInstall
  '';

  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/esp-emu" --version
    "$out/bin/esp-emu" --help > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Prebuilt emulator for Espressif ESP32 series SoCs";
    homepage = "https://github.com/espressif/esp-emulator";
    license = lib.licenses.asl20;
    mainProgram = "esp-emu";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
