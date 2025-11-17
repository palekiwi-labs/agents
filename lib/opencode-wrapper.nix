{ pkgs }:

{ image, imageName, variant ? "", cargoCache ? false }:
let
  utils = import ./utils.nix { inherit pkgs; };
  inherit (utils) generate_port_from_path;
in
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
    CONFIG_DIR="''${OPENCODE_CONFIG_DIR:-$HOME/.config/agent-opencode}"
    mkdir -p "$CONFIG_DIR"

    # Generate container name from parent and base directory
    PARENT_DIR=$(basename "$(dirname "$PWD")")
    BASE_DIR=$(basename "$PWD")
    CONTAINER_NAME="''${OPENCODE_CONTAINER_NAME:-opencode-''${PARENT_DIR}-''${BASE_DIR}}"

    WORKSPACE="''${OPENCODE_WORKSPACE:-''${AGENTS_WORKSPACE:-}}"
    PORT="''${OPENCODE_PORT:-$(${generate_port_from_path})}"

    if [[ -z "$WORKSPACE" ]]; then
      echo "Error: OPENCODE_WORKSPACE or AGENTS_WORKSPACE environment variable is required" >&2
      echo "Set it to the directory you want to mount as the workspace" >&2
      exit 1
    fi

    if [[ ! -d "$WORKSPACE" ]]; then
      echo "Error: OPENCODE_WORKSPACE '$WORKSPACE' is not a directory" >&2
      exit 1
    fi

    WORKSPACE=$(realpath "$WORKSPACE")

    SHADOW_MOUNTS=()
    if [[ -n "''${AGENTS_FORBIDDEN:-}" ]]; then
      IFS=':' read -ra PATHS <<< "$AGENTS_FORBIDDEN"
      for path in "''${PATHS[@]}"; do
        if [[ -n "$path" ]]; then
          FULL_PATH="$WORKSPACE/$path"
          if [[ -d "$FULL_PATH" ]]; then
            SHADOW_MOUNTS+=(--tmpfs "/workspace/$(basename "$WORKSPACE")/$path:ro,noexec,nosuid,size=1k,mode=000")
          elif [[ -f "$FULL_PATH" ]]; then
            SHADOW_MOUNTS+=(-v "/dev/null:/workspace/$(basename "$WORKSPACE")/$path:ro")
          fi
        fi
      done
    fi
  
    exec docker run --rm -it \
      --read-only \
      --tmpfs /tmp:noexec,nosuid,size=500m \
      --tmpfs /workspace/tmp:exec,nosuid,size=500m \
      ${if cargoCache then 
        ''-v "opencode-cargo-$PORT:/home/agent/.cargo:rw"''
      else 
        ''''} \
      --security-opt no-new-privileges \
      --cap-drop ALL \
      --network "''${OPENCODE_NETWORK:-bridge}" \
      --memory "''${OPENCODE_MEMORY:-1024m}" \
      --cpus "''${OPENCODE_CPUS:-1.0}" \
      --pids-limit "''${OPENCODE_PIDS_LIMIT:-100}" \
      -p "$PORT:80" \
      -e USER="agent" \
      -e TERM="xterm-256color" \
      -e COLORTERM="truecolor" \
      -e FORCE_COLOR=1 \
      -e CONTEXT7_API_KEY="''${CONTEXT7_API_KEY}" \
      -e GEMINI_API_KEY="''${GEMINI_API_KEY:-""}" \
      -e OPENCODE_API_KEY="''${OPENCODE_API_KEY}" \
      -e OPENCODE_ENABLE_EXPERIMENTAL_MODELS="''${OPENCODE_ENABLE_EXPERIMENTAL_MODELS:-false}" \
      -e ZAI_CODING_PLAN_API_KEY="''${ZAI_CODING_PLAN_API_KEY}" \
      -e TMPDIR="/workspace/tmp" \
      -v "opencode-cache-$PORT:/home/agent/.cache:rw" \
      -v "opencode-local-$PORT:/home/agent/.local:rw" \
      -v "$CONFIG_DIR:/home/agent/.config/opencode:ro" \
      -v "$WORKSPACE:/workspace/$(basename "$WORKSPACE"):rw" \
      -v /etc/localtime:/etc/localtime:ro \
      -v /etc/timezone:/etc/timezone:ro \
      "''${SHADOW_MOUNTS[@]}" \
      --workdir "/workspace/$(basename "$WORKSPACE")" \
      --name "$CONTAINER_NAME" \
      "$IMAGE_NAME" opencode "$@"
  '';
}
