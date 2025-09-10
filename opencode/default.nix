{ pkgs, pkgs-master }:

let
  inherit (pkgs.dockerTools) buildImage streamLayeredImage;
in

rec {
  agentConfig = {
    User = "agent";
    Cmd = [ "opencode" ];
    WorkingDir = "/workspace";
    Volumes = {
      "/workspace" = { };
      "/home/agent/.cache" = { };
      "/home/agent/.local" = { };
    };
  };

  base = buildImage {
    name = "agent-base";
    tag = "latest";

    copyToRoot = with pkgs; buildEnv {
      name = "image-root";
      paths = [
        bashInteractive
        coreutils
        curl
        git
        gnugrep
        gnused
        gnutar
        gzip
        ripgrep

      ];
      pathsToLink = [ "/bin" ];
    };

    runAsRoot = ''
      #!${pkgs.runtimeShell}
      ${pkgs.dockerTools.shadowSetup}
      groupadd agent
      useradd -g agent -m -d /home/agent agent

      mkdir -p /workspace
      chown agent:agent /workspace

      mkdir /home/agent/.cache
      chown agent:agent /home/agent/.cache

      mkdir /home/agent/.local
      chown agent:agent /home/agent/.local
    '';
  };

  opencode = streamLayeredImage {
    name = "agent-opencode";
    tag = "latest";

    fromImage = base;

    contents = [ pkgs-master.opencode ];

    config = agentConfig;
  };

  opencode-rust = streamLayeredImage {
    name = "agent-opencode";
    tag = "rust-latest";

    fromImage = base;

    contents = [ pkgs-master.opencode pkgs.rust-analyzer ];

    config = agentConfig;
  };
}
