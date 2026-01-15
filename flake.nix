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
        
        # Registry prefix (can be overridden via env var)
        registry = builtins.getEnv "REGISTRY";
        registryPrefix = if registry != "" then "${registry}/" else "localhost/";

        mkOpencodeWrapper = import ./lib/opencode-wrapper.nix { inherit pkgs; };
        mkGeminiWrapper = import ./lib/gemini-wrapper.nix { inherit pkgs; };

        opencodeWrapper = mkOpencodeWrapper {
          imageName = "${registryPrefix}agent-opencode:${opencodeVersion}";
        };

        opencodeRustWrapper = mkOpencodeWrapper {
          imageName = "${registryPrefix}agent-opencode:${opencodeVersion}-rust";
          variant = "rust";
          cargoCache = true;
        };

        opencodeRubyWrapper = mkOpencodeWrapper {
          imageName = "${registryPrefix}agent-opencode:${opencodeVersion}-ruby";
          variant = "ruby";
        };

        geminiWrapper = mkGeminiWrapper {
          imageName = "${registryPrefix}agent-gemini-cli:${geminiVersion}";
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

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            docker
            go-task
            jq
            curl
          ];
          
          shellHook = ''
            echo "Docker + go-task development environment"
            echo "Available commands:"
            echo "  task --list    : Show all available build tasks"
            echo "  task build:all : Build all Docker images"
            echo "  task test:all  : Test all Docker images"
            echo ""
            echo "Wrapper commands (via Nix):"
            echo "  nix run .#opencode      : Run OpenCode"
            echo "  nix run .#opencode-rust : Run OpenCode with Rust"
            echo "  nix run .#opencode-ruby : Run OpenCode with Ruby"
            echo "  nix run .#gemini        : Run Gemini CLI"
          '';
        };
      }
    );
}
