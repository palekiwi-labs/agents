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
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
  };

  outputs = { nixpkgs, nixpkgs-unstable, flake-utils, fenix, nixpkgs-ruby, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nixpkgs-ruby.overlays.default
          ];
        };
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
        fenix-pkgs = fenix.packages.${system}.stable;

        opencodeImages = import ./images { 
          inherit pkgs pkgs-unstable fenix-pkgs; 
        };

        mkOpencodeWrapper = import ./lib/opencode-wrapper.nix { inherit pkgs; };
        mkGeminiCliWrapper = import ./lib/gemini-cli-wrapper.nix { inherit pkgs; };

        opencodeWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode;
          imageName = "agent-opencode:${pkgs-unstable.opencode.version}";
        };

        opencodeRustWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode-rust;
          imageName = "agent-opencode:${pkgs-unstable.opencode.version}-rust";
          variant = "rust";
          cargoCache = true;
        };

        rubyVersion = pkgs.lib.fileContents ./images/ruby/.ruby-version;
        
        opencodeRubyWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode-ruby;
          imageName = "agent-opencode:ruby-${rubyVersion}";
          variant = "ruby";
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
          opencode-ruby = opencodeRubyWrapper;

          gemini-cli = geminiCliWrapper;

          opencode-image-script = opencodeImages.opencode;
          opencode-rust-image-script = opencodeImages.opencode-rust;
          opencode-ruby-image-script = opencodeImages.opencode-ruby;
        };
      }
    );
}
