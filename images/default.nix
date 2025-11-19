{ pkgs, fenix-pkgs, opencode-pkg }:

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

  rubyAgentConfig = baseAgentConfig // {
    Volumes = baseAgentConfig.Volumes // {
      "/home/agent/.bundle" = { };
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
        jq
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

      mkdir /home/agent/.bundle
      chown agent:agent /home/agent/.bundle

      mkdir -p /usr/bin
      ln -s ${pkgs.coreutils}/bin/env /usr/bin/env
    '';
  };

  opencode = 
    streamLayeredImage {
      name = "agent-opencode";
      tag = opencode-pkg.version;

      fromImage = base;

      contents = [ opencode-pkg ];

      config = baseAgentConfig;
    };

  opencode-rust = streamLayeredImage {
    name = "agent-opencode";
    tag = "${opencode-pkg.version}-rust";

    fromImage = base;

    contents = [
      opencode-pkg
      pkgs.gcc
      (fenix-pkgs.withComponents [
        "cargo"
        "rustc"
        "rust-analyzer"
        "rust-src"
        "rust-std"
        "rustfmt"
        "clippy"
      ])
    ];

    config = cargoAgentConfig;
  };

  opencode-ruby = 
    let
      rubyVersion = pkgs.lib.fileContents ./ruby/.ruby-version;
      rubyPkg = pkgs."ruby-${rubyVersion}";
      
      gems = pkgs.bundlerEnv {
        name = "opencode-ruby-gems";
        ruby = rubyPkg;
        gemdir = ./ruby;
      };
    in
    streamLayeredImage {
      name = "agent-opencode";
      tag = "${opencode-pkg.version}-ruby";
      
      fromImage = base;
      
      contents = [
        opencode-pkg
        rubyPkg
        gems
      ];
      
      config = rubyAgentConfig;
    };

  gemini =
    let
      gemini-cli-pkg = pkgs.callPackage ../pkgs/gemini-cli-bin.nix { };
    in
    streamLayeredImage {
      name = "agent-gemini-cli";
      tag = gemini-cli-pkg.version;

      fromImage = base;

      contents = [ gemini-cli-pkg ];

      config = baseAgentConfig;
    };
}
