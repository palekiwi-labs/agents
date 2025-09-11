{
  description = "Secure Docker wrapper for OpenCode AI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, nixpkgs-unstable, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};

        generate_port_from_path = pkgs.writeShellScript "generate_port_from_path" ''
          # Generate a deterministic port (32768-65535) based on directory path
          # This ensures consistent ports per workspace while avoiding system/privileged ports
          parent_dir=$(basename "$(dirname "$PWD")")
          current_dir=$(basename "$PWD")
          pathHash="''${parent_dir}''${current_dir}"
          port=$(echo -n "$pathHash" | cksum | cut -d' ' -f1)
          echo $((32768 + (port % 32768)))
        '';

        opencodeImages = import ./opencode { inherit pkgs pkgs-unstable; };

        mkOpencodeWrapper = { image, imageName, variant ? "" }:
          pkgs.writeShellApplication {
            name = "opencode${if variant != "" then "-${variant}" else ""}";
            runtimeInputs = [ pkgs.docker ];
            text = ''
              IMAGE_NAME="${imageName}"

              # Load image if not present
              if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
                echo "Loading opencode Docker image..." >&2
                ${image} | docker load
              fi
            
              # Create isolated config directory
              CONFIG_DIR="$HOME/.config/agent-opencode"
              mkdir -p "$CONFIG_DIR"

              # Generate container name from parent and base directory
              PARENT_DIR=$(basename "$(dirname "$PWD")")
              BASE_DIR=$(basename "$PWD")
              CONTAINER_NAME="opencode-''${PARENT_DIR}-''${BASE_DIR}"

              WORKSPACE="''${OPENCODE_WORKSPACE:-""}"
              PORT="$(${generate_port_from_path})"

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
                -v "opencode-cache-$PORT:/home/agent/.cache:rw" \
                -v "opencode-local-$PORT:/home/agent/.local:rw" \
                -v "$CONFIG_DIR:/home/agent/.config/opencode:ro" \
                -v "$WORKSPACE:/workspace/$(basename "$WORKSPACE"):rw" \
                --workdir "/workspace/$(basename "$WORKSPACE")" \
                --name "$CONTAINER_NAME" \
                "$IMAGE_NAME" opencode "$@"
            '';
          };

        opencodeWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode;
          imageName = "agent-opencode:latest";
        };

        opencodeRustWrapper = mkOpencodeWrapper {
          image = opencodeImages.opencode-rust;
          imageName = "agent-opencode:rust-latest";
          variant = "rust";
        };

      in
      {
        packages = {
          default = opencodeWrapper;

          opencode = opencodeWrapper;
          opencode-rust = opencodeRustWrapper;

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
