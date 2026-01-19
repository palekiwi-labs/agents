{ pkgs }:

{ imageName, variant ? "" }:
pkgs.writeShellApplication {
  name = "gemini${if variant != "" then "-${variant}" else ""}";
  runtimeInputs = [ pkgs.go-task ];
  text = ''
    IMAGE_NAME="${imageName}"

    # Check if image exists locally, if not build it
    if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
      echo "Image $IMAGE_NAME not found locally." >&2
      echo "Building image with go-task..." >&2
      task build:gemini
      if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        echo "Error: Failed to build image $IMAGE_NAME" >&2
        exit 1
      fi
    fi
  
    # Create isolated config directory
    CONFIG_DIR="''${GEMINI_CONFIG_DIR:-$HOME/.config/agent-gemini-cli}"
    mkdir -p "$CONFIG_DIR"

    # Generate container name from parent and base directory
    PARENT_DIR=$(basename "$(dirname "$PWD")")
    BASE_DIR=$(basename "$PWD")
    CONTAINER_NAME="''${GEMINI_CONTAINER_NAME:-gemini-cli-''${PARENT_DIR}-''${BASE_DIR}}"

    WORKSPACE="''${GEMINI_WORKSPACE:-''${AGENTS_WORKSPACE:-}}"

    if [[ -z "$WORKSPACE" ]]; then
      echo "Error: GEMINI_WORKSPACE or AGENTS_WORKSPACE environment variable is required" >&2
      echo "Set it to the directory you want to mount as the workspace" >&2
      exit 1
    fi

    if [[ ! -d "$WORKSPACE" ]]; then
      echo "Error: GEMINI_WORKSPACE '$WORKSPACE' is not a directory" >&2
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
      --security-opt no-new-privileges \
      --cap-drop ALL \
      --network "''${GEMINI_NETWORK:-bridge}" \
      --memory "''${GEMINI_MEMORY:-1024m}" \
      --cpus "''${GEMINI_CPUS:-1.0}" \
      --pids-limit "''${GEMINI_PIDS_LIMIT:-100}" \
      -e USER="agent" \
      -e TERM="xterm-256color" \
      -e COLORTERM="truecolor" \
      -e FORCE_COLOR=1 \
      -e TMPDIR="/workspace/tmp" \
      -e CONTEXT7_API_KEY="''${CONTEXT7_API_KEY:-""}" \
      -v "$CONFIG_DIR:/home/agent/.gemini" \
       -v "$WORKSPACE:/workspace/$(basename "$WORKSPACE"):rw" \
       -v /etc/localtime:/etc/localtime:ro \
       "''${SHADOW_MOUNTS[@]}" \
      --workdir "/workspace/$(basename "$WORKSPACE")" \
      --name "$CONTAINER_NAME" \
      "$IMAGE_NAME" gemini "$@"
  '';
}
