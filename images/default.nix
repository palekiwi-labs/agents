{ pkgs, fenix-pkgs, opencode-pkg }:

let
  inherit (pkgs.dockerTools) buildImage streamLayeredImage;
in

rec {
  baseAgentConfig = {
    User = "user";
    Cmd = [ "opencode" ];
    WorkingDir = "/workspace";
    Env = [
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    Volumes = {
      "/workspace" = { };
      "/home/user/.cache" = { };
      "/home/user/.local" = { };
    };
  };

  cargoAgentConfig = baseAgentConfig // {
    Volumes = baseAgentConfig.Volumes // {
      "/home/user/.cargo" = { };
    };
  };

  rubyAgentConfig = baseAgentConfig // {
    Volumes = baseAgentConfig.Volumes // {
      "/home/user/.bundle" = { };
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
      groupadd user
      useradd -g user -m -d /home/user user

      mkdir -p /workspace
      chown user:user /workspace

      mkdir /home/user/.cache
      chown user:user /home/user/.cache

      mkdir /home/user/.local
      chown user:user /home/user/.local

      mkdir /home/user/.cargo
      chown user:user /home/user/.cargo

      mkdir /home/user/.bundle
      chown user:user /home/user/.bundle

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
