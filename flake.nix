{
  description = "Secure Docker wrapper for OpenCode AI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    opencode.url = "github:sst/opencode";
  };

  outputs = { nixpkgs, flake-utils, fenix, nixpkgs-ruby, opencode, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nixpkgs-ruby.overlays.default
          ];
        };
        fenix-pkgs = fenix.packages.${system}.stable;
        opencode-pkg = opencode.packages.${system}.default;

        opencodeImages = import ./images { 
          inherit pkgs fenix-pkgs opencode-pkg; 
        };

        mkOpencodeWrapper = import ./lib/opencode-wrapper.nix { inherit pkgs; };

        opencodeWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode;
          imageName = "agent-opencode:${opencode-pkg.version}";
        };

        opencodeRustWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode-rust;
          imageName = "agent-opencode:${opencode-pkg.version}-rust";
          variant = "rust";
          cargoCache = true;
        };

        opencodeRubyWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode-ruby;
          imageName = "agent-opencode:${opencode-pkg.version}-ruby";
          variant = "ruby";
        };
      in
      {
        packages = {
          default = opencodeWrapper;

          opencode = opencodeWrapper;
          opencode-rust = opencodeRustWrapper;
          opencode-ruby = opencodeRubyWrapper;

          opencode-image-script = opencodeImages.opencode;
          opencode-rust-image-script = opencodeImages.opencode-rust;
          opencode-ruby-image-script = opencodeImages.opencode-ruby;
        };
      }
    );
}
