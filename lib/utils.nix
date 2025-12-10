{ pkgs }:

{
  generate_port_from_name = pkgs.writeShellScript "generate_port_from_name" ''
    #!/usr/bin/env bash
    # Generate a deterministic port (32768-65535) based on container name
    # This ensures consistent ports per container while avoiding system/privileged ports
    container_name="$1"
    if [[ -z "$container_name" ]]; then
      echo "Error: container name required" >&2
      exit 1
    fi
    port=$(echo -n "$container_name" | cksum | cut -d' ' -f1)
    echo $((32768 + (port % 32768)))
  '';
}