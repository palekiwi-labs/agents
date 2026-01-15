{
  description = "Secure Docker wrapper for OpenCode AI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Read versions from files
        opencodeVersion = builtins.readFile ./docker/.opencode-version;
        geminiVersion = builtins.readFile ./docker/.gemini-version;

        mkOpencodeWrapper = import ./lib/opencode-wrapper.nix { inherit pkgs; };
        mkGeminiWrapper = import ./lib/gemini-wrapper.nix { inherit pkgs; };

        opencodeWrapper = mkOpencodeWrapper {
          imageName = "localhost/agent-opencode:${opencodeVersion}";
        };

        opencodeRustWrapper = mkOpencodeWrapper {
          imageName = "localhost/agent-opencode:${opencodeVersion}-rust";
          variant = "rust";
          cargoCache = true;
        };

        opencodeRubyWrapper = mkOpencodeWrapper {
          imageName = "localhost/agent-opencode:${opencodeVersion}-ruby";
          variant = "ruby";
        };

        geminiWrapper = mkGeminiWrapper {
          imageName = "localhost/agent-gemini-cli:${geminiVersion}";
        };

      in
      {
        packages = {
          default = opencodeWrapper;
          opencode = opencodeWrapper;
          opencode-rust = opencodeRustWrapper;
          opencode-ruby = opencodeRubyWrapper;
          gemini = geminiWrapper;
        };
      }
    );
}
