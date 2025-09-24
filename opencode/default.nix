{ pkgs, pkgs-unstable, fenix-pkgs }:

let
  inherit (pkgs.dockerTools) buildImage streamLayeredImage;
in

rec {
  baseAgentConfig = {
    User = "agent";
    Cmd = [ "opencode" ];
    WorkingDir = "/workspace";
    Env = [
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    Volumes = {
      "/workspace" = { };
      "/home/agent/.cache" = { };
      "/home/agent/.local" = { };
    };
  };

  cargoAgentConfig = baseAgentConfig // {
    Volumes = baseAgentConfig.Volumes // {
      "/home/agent/.cargo" = { };
    };
  };

  base = buildImage {
    name = "agent-base";
    tag = "latest";

    copyToRoot = with pkgs; buildEnv {
      name = "image-root";
      paths = [
        bashInteractive
        cacert
        coreutils
        curl
        fd
        findutils
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

      mkdir /home/agent/.cargo
      chown agent:agent /home/agent/.cargo
    '';
  };

  opencode = streamLayeredImage {
    name = "agent-opencode";
    tag = "latest";

    fromImage = base;

    contents = [ pkgs-unstable.opencode ];

    config = baseAgentConfig;
  };

  opencode-rust = streamLayeredImage {
    name = "agent-opencode";
    tag = "rust-latest";

    fromImage = base;

    contents = [ pkgs-unstable.opencode pkgs.rust-analyzer ];

    config = baseAgentConfig;
  };

  opencode-rust-enhanced = streamLayeredImage {
    name = "agent-opencode";
    tag = "rust-enhanced-latest";

    fromImage = base;

    contents = [
      pkgs-unstable.opencode
      pkgs.rust-analyzer
      pkgs.gcc
      (fenix-pkgs.withComponents [
        "cargo"
        "rustc" 
        "rust-std"
        "rustfmt"
        "clippy"
      ])
    ];

    config = cargoAgentConfig;
  };

  gemini-cli = streamLayeredImage {
    name = "agent-gemini-cli";
    tag = "latest";

    fromImage = base;

    contents = [ pkgs-unstable.gemini-cli-bin ];

    config = baseAgentConfig;
  };
}
