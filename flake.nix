{
  description = "Secure Docker wrapper for OpenCode AI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, flake-utils, fenix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
        fenix-pkgs = fenix.packages.${system}.stable;

        opencodeImages = import ./images { inherit pkgs pkgs-unstable fenix-pkgs; };

        mkOpencodeWrapper = import ./lib/opencode-wrapper.nix { inherit pkgs; };
        mkGeminiCliWrapper = import ./lib/gemini-cli-wrapper.nix { inherit pkgs; };

        opencodeWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode;
          imageName = "agent-opencode:latest";
        };

        opencodeRustWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode-rust;
          imageName = "agent-opencode:rust-latest";
          variant = "rust";
          cargoCache = true;
        };

        geminiCliWrapper = mkGeminiCliWrapper {
          image = opencodeImages.gemini-cli;
          imageName = "agent-gemini-cli:${(pkgs.callPackage ./pkgs/gemini-cli-bin.nix {}).version}";
        };

      in
      {
        packages = {
          default = opencodeWrapper;

          opencode = opencodeWrapper;
          opencode-rust = opencodeRustWrapper;

          gemini-cli = geminiCliWrapper;

          opencode-image-script = opencodeImages.opencode;
          opencode-rust-image-script = opencodeImages.opencode-rust;
        };

        apps = rec {
          opencode = {
            type = "app";
            program = "${opencodeWrapper}/bin/opencode";
          };

          opencode-rust = {
            type = "app";
            program = "${opencodeRustWrapper}/bin/opencode-rust";
          };

          default = opencode;
        };
      }
    );
}
