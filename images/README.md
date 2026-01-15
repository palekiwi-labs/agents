# Images Directory

This directory previously contained Nix-based image building code (`default.nix`).

The image building has been migrated to standard Dockerfiles located in the `docker/` directory.

The old Nix build code is preserved in `default.nix.bak` for reference.

## Current Contents

- `ruby/` - Ruby Gemfile and dependencies used by `docker/Dockerfile.ruby`
  - `.ruby-version` - Ruby version specification
  - `Gemfile` - Ruby gem dependencies
  - `Gemfile.lock` - Locked gem versions for reproducibility
