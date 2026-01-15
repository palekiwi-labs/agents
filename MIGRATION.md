# Migration from Nix dockerTools to Dockerfiles

## Date: 2026-01-15

## Reason

Migrated from Nix's `dockerTools.buildImage` and `streamLayeredImage` to standard Dockerfiles for:
- Better compatibility with standard Docker workflows
- Easier CI/CD integration
- More familiar to Docker users
- x86_64 architecture support only (simplified)
- Easier maintenance

## What Changed

### Before (Nix-based)
- Images built via `images/default.nix` using `dockerTools`
- Build command: `nix build .#opencode-image-script && result | docker load`
- Tightly coupled with Nix ecosystem

### After (Docker-based)
- Images built via standard Dockerfiles in `docker/` directory
- Build automation via go-task (`Taskfile.yml`)
- Build command: `task build:all`
- Nix still used for wrapper scripts and dev environment

## What Stayed the Same

- Security hardening features
- Wrapper scripts (still Nix-based)
- Image functionality and behavior
- User experience when running containers

## Rollback Plan

If needed, the old Nix-based image building is preserved in `images/default.nix.bak`.
