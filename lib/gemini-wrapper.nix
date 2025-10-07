{ pkgs }:

{ image, imageName, variant ? "" }:
pkgs.writeShellApplication {
  name = "gemini${if variant != "" then "-${variant}" else ""}";
  runtimeInputs = [ pkgs.docker ];
  text = ''
    IMAGE_NAME="${imageName}"

    # Load image if not present
    if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
      echo "Loading gemini-cli Docker image..." >&2
      ${image} | docker load
    fi
  
    # Create isolated config directory
    CONFIG_DIR="$HOME/.config/agent-gemini-cli"
    mkdir -p "$CONFIG_DIR"

    # Generate container name from parent and base directory
    PARENT_DIR=$(basename "$(dirname "$PWD")")
    BASE_DIR=$(basename "$PWD")
    CONTAINER_NAME="gemini-cli-''${PARENT_DIR}-''${BASE_DIR}"

    WORKSPACE="''${GEMINI_WORKSPACE:-""}"

    if [[ -z "$WORKSPACE" ]]; then
      echo "Error: GEMINI_WORKSPACE environment variable is required" >&2
      echo "Set it to the directory you want to mount as the workspace" >&2
      exit 1
    fi

    if [[ ! -d "$WORKSPACE" ]]; then
      echo "Error: GEMINI_WORKSPACE '$WORKSPACE' is not a directory" >&2
      exit 1
    fi

    WORKSPACE=$(realpath "$WORKSPACE")
  
    exec docker run --rm -it \
      --read-only \
      --tmpfs /tmp:noexec,nosuid,size=500m \
      --tmpfs /workspace/tmp:exec,nosuid,size=500m \
      --security-opt no-new-privileges \
      --cap-drop ALL \
      --network bridge \
      --memory 1024m \
      --cpus 1.0 \
      --pids-limit 100 \
      -e USER="agent" \
      -e TERM="xterm-256color" \
      -e COLORTERM="truecolor" \
      -e FORCE_COLOR=1 \
      -e TMPDIR="/workspace/tmp" \
      -v "$CONFIG_DIR:/home/agent/.gemini" \
      -v "$WORKSPACE:/workspace/$(basename "$WORKSPACE"):rw" \
      -v /dev/null:/workspace/config/cloudinary.yml:ro \
      -v /dev/null:/workspace/config/secrets.yml:ro \
      --workdir "/workspace/$(basename "$WORKSPACE")" \
      --name "$CONTAINER_NAME" \
      "$IMAGE_NAME" gemini "$@"
  '';
}
