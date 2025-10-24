{ lib, stdenvNoCC, fetchurl, nodejs }:

stdenvNoCC.mkDerivation rec {
  pname = "gemini-cli-bin";
  version = "0.10.0";

  src = fetchurl {
    url = "https://github.com/google-gemini/gemini-cli/releases/download/v${version}/gemini.js";
    hash = "sha256-jwyx5HWjPi2S5GQFxV+VeuwrmjmLi+F1nzw4YMfNSiA=";
  };

  phases = [ "installPhase" "fixupPhase" ];
  strictDeps = true;
  buildInputs = [ nodejs ];

  installPhase = ''
    runHook preInstall
    install -D "$src" "$out/bin/gemini"
    runHook postInstall
  '';

  meta = {
    description = "AI agent that brings the power of Gemini directly into your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = lib.licenses.asl20;
    mainProgram = "gemini";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
}
