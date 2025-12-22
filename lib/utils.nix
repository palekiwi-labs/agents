{ pkgs }:

{
  generate_port_from_path = pkgs.writeShellScript "generate_port_from_path" ''
    #!/usr/bin/env bash
    # Generate a deterministic port (32768-65535) based on directory path
    # This ensures consistent ports per workspace while avoiding system/privileged ports
    parent_dir=$(basename "$(dirname "$PWD")")
    current_dir=$(basename "$PWD")
    pathHash="''${parent_dir}''${current_dir}"
    port=$(echo -n "$pathHash" | cksum | cut -d' ' -f1)
    echo $((32768 + (port % 32768)))
  '';
}
