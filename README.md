# Containerized Agentic CLI Tools

A secure Docker wrapper for OpenCode AI that provides isolated, containerized execution with strict security constraints.

## Overview

This project creates a secure, containerized environment for running OpenCode AI agents with:

- **Security-first design**: Read-only filesystem, dropped capabilities, resource limits
- **Workspace isolation**: Only mounts specified directories with controlled access
- **Deterministic ports**: Generates consistent ports based on workspace path
- **Nix-based builds**: Reproducible container images using Nix flakes

## Features

- **Secure execution**: Runs in a hardened container with minimal privileges
- **Resource constraints**: Limited memory (512MB), CPU (1.0), and process limits (100)
- **Network isolation**: Bridge networking with controlled port exposure
- **Workspace mounting**: Secure mounting of specified workspace directories
- **Configuration isolation**: Separate config directories per workspace

## Prerequisites

- Nix
- Docker
- `OPENCODE_WORKSPACE` environment variable (automatically set to current directory via `.envrc`)

## Usage

### Setup

1. Set your workspace directory:
```bash
export OPENCODE_WORKSPACE=/path/to/your/workspace
```

2. Run OpenCode:
```bash
nix run
```

Or using the specific app:
```bash
nix run .#opencode
```

### Variants

Multiple variants are available with specialized tooling:

- **Default**: Basic OpenCode with essential tools
- **Rust**: Includes rust-analyzer for Rust development
  ```bash
  nix run .#opencode-rust
  ```

### Security Features

The container runs with strict security measures:

- **Read-only filesystem** with limited writable tmpfs
- **Dropped capabilities** (CAP_DROP ALL)
- **No new privileges** security option
- **Resource limits**: 512MB memory, 1.0 CPU, 100 process limit
- **User isolation**: Runs as non-root `agent` user

### Container Management

Each workspace gets a unique container name based on the parent and current directory names:
- Container name: `opencode-{parent-dir}-{current-dir}`
- Port: Deterministically generated from directory path (32768-65535)
- Volumes: Workspace-specific cache and local directories

## Build Targets

### Applications
- `nix run` - Run OpenCode wrapper (default)
- `nix run .#opencode` - Run default OpenCode wrapper
- `nix run .#opencode-rust` - Run Rust-enabled OpenCode wrapper

### Packages
- `nix build .#opencode` - Build default OpenCode wrapper
- `nix build .#opencode-rust` - Build Rust-enabled OpenCode wrapper

### Container Image Scripts
- `nix build .#opencode-image-script` - Build script for default container image
- `nix build .#opencode-rust-image-script` - Build script for Rust container image

To build and load images manually:
```bash
# Build and load default image
nix build .#opencode-image-script && result | docker load

# Build and load Rust image  
nix build .#opencode-rust-image-script && result | docker load

# Or run directly without building first
nix run .#opencode-image-script | docker load
nix run .#opencode-rust-image-script | docker load
```

## Architecture

- **Base image**: Minimal container with essential tools (bash, coreutils, git, ripgrep)
- **OpenCode layer**: Adds OpenCode AI from nixpkgs-master
- **Specialized variants**: Additional tooling (rust-analyzer for Rust development)
- **Wrapper script**: Handles container lifecycle, security, and workspace mounting with variant-specific image selection

## Development

The project uses Nix flakes for reproducible builds and includes:
- Security-hardened Docker configuration
- Workspace-isolated execution
- Deterministic port allocation
- Read-only container filesystem
