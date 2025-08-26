{
  description = "Secure Docker wrapper for OpenCode AI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        opencodeImages = import ./opencode { inherit pkgs; };

        opencodeWrapper = pkgs.writeShellApplication {
          name = "opencode";
          runtimeInputs = [ pkgs.docker ];
          text = ''
            IMAGE_NAME="agent-opencode"

            # Load image if not present
            if ! docker image inspect "$IMAGE_NAME:latest" > /dev/null 2>&1; then
              echo "Loading opencode Docker image..." >&2
              ${opencodeImages.opencode} | docker load
            fi
            
            # Create isolated config directory
            CONFIG_DIR="$HOME/.config/agent-opencode"
            mkdir -p "$CONFIG_DIR"

            WORKSPACE="''${OPENCODE_WORKSPACE:-""}"
            PORT="''${OPENCODE_PORT:-"49000"}"

            if [[ -z "$WORKSPACE" ]]; then
              echo "Error: OPENCODE_WORKSPACE environment variable is required" >&2
              echo "Set it to the directory you want to mount as the workspace" >&2
              exit 1
            fi

            if [[ ! -d "$WORKSPACE" ]]; then
              echo "Error: OPENCODE_WORKSPACE '$WORKSPACE' is not a directory" >&2
              exit 1
            fi

            WORKSPACE=$(realpath "$WORKSPACE")
            
            exec docker run --rm -it \
              --read-only \
              --tmpfs /tmp:noexec,nosuid,size=100m \
              --security-opt no-new-privileges \
              --cap-drop ALL \
              --network bridge \
              --memory 512m \
              --cpus 1.0 \
              --pids-limit 100 \
              -p "$PORT:80" \
              -e USER="agent" \
              -e TERM="xterm-256color" \
              -e COLORTERM="truecolor" \
              -e FORCE_COLOR=1 \
              -v "opencode-cache:/home/agent/.cache:rw" \
              -v "opencode-local:/home/agent/.local:rw" \
              -v "$CONFIG_DIR:/home/agent/.config/opencode:ro" \
              -v "$WORKSPACE:/workspace:rw" \
              "$IMAGE_NAME:latest" opencode --port 80 --hostname 0.0.0.0 "$@"
          '';
        };

      in
      {
        packages = {
          default = opencodeWrapper;

          opencode = opencodeWrapper;
          opencode-image = opencodeImages.opencode;
        };

        apps = rec {
          opencode = {
            type = "app";
            program = "${opencodeWrapper}/bin/opencode";
          };

          default = opencode;
        };
      }
    );
}
