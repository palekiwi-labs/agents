{ lib, stdenvNoCC, fetchurl, nodejs }:

stdenvNoCC.mkDerivation rec {
  pname = "gemini-cli-bin";
  version = "0.8.1";

  src = fetchurl {
    url = "https://github.com/google-gemini/gemini-cli/releases/download/v${version}/gemini.js";
    hash = "sha256-SRtl8FPMI0VBz0hzmyvtGYPO3mdnm60gu2zlStb5r98=";
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
