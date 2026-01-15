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

- Docker
- [go-task](https://taskfile.dev) (install: `brew install go-task` or see [installation guide](https://taskfile.dev/installation/))
- Nix (optional, for wrapper scripts)
- `OPENCODE_WORKSPACE` or `AGENTS_WORKSPACE` environment variable set to your workspace directory

## Usage

### Setup

1. Set your workspace directory:
```bash
export OPENCODE_WORKSPACE=/path/to/your/workspace
# Or use the shared workspace variable
export AGENTS_WORKSPACE=/path/to/your/workspace
```

2. Run OpenCode:
```bash
nix run
```

Or using the specific app:
```bash
nix run .#opencode
```

### Environment Variables

#### Workspace Configuration
- `AGENTS_WORKSPACE` - Shared workspace directory for all agents (fallback for both OpenCode and Gemini)
- `OPENCODE_WORKSPACE` - OpenCode-specific workspace directory (overrides `AGENTS_WORKSPACE`)
- `GEMINI_WORKSPACE` - Gemini-specific workspace directory (overrides `AGENTS_WORKSPACE`)

#### OpenCode Configuration
- `OPENCODE_CONTAINER_NAME` - Container name (default: `opencode-{parent-dir}-{current-dir}`)
- `OPENCODE_PORT` - Port mapping (default: deterministically generated from path, 32768-65535)
- `OPENCODE_CONFIG_DIR` - Configuration directory (default: `$HOME/.config/agent-opencode`)
- `OPENCODE_NETWORK` - Docker network mode (default: `bridge`)
- `OPENCODE_MEMORY` - Memory limit (default: `1024m`)
- `OPENCODE_CPUS` - CPU limit (default: `1.0`)
- `OPENCODE_PIDS_LIMIT` - Process limit (default: `100`)

#### Gemini Configuration
- `GEMINI_CONTAINER_NAME` - Container name (default: `gemini-cli-{parent-dir}-{current-dir}`)
- `GEMINI_CONFIG_DIR` - Configuration directory (default: `$HOME/.config/agent-gemini-cli`)
- `GEMINI_NETWORK` - Docker network mode (default: `bridge`)
- `GEMINI_MEMORY` - Memory limit (default: `1024m`)
- `GEMINI_CPUS` - CPU limit (default: `1.0`)
- `GEMINI_PIDS_LIMIT` - Process limit (default: `100`)

#### Security Configuration
- `AGENTS_FORBIDDEN` - Colon-separated list of paths to shadow mount (block access to specific files/directories within workspace)

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
- Port publishing can be disabled via `OPENCODE_PUBLISH_PORT=false`

### Disabling Port Publishing

By default, OpenCode publishes its web interface on a deterministic port. If you don't need web access and want to run in pure CLI mode, you can disable port publishing:

```bash
export OPENCODE_PUBLISH_PORT=false
nix run .#opencode
```

**Note:** The port number is still generated and used for volume naming to ensure workspace isolation, even when publishing is disabled. This ensures that different workspaces maintain separate cache and configuration volumes.

## Building Images

This project uses [go-task](https://taskfile.dev) for build automation and standard Dockerfiles for container images.

### Building Images

```bash
# Build all images
task build:all

# Build specific images
task build:base
task build:opencode
task build:rust
task build:ruby
task build:gemini

# Show build info (versions, etc.)
task info

# Test images
task test:all
```

### Available Tasks

Run `task --list` to see all available tasks:
- `build:*` - Build specific or all images
- `test:*` - Test specific or all images
- `push:all` - Push all images to registry
- `clean` - Remove all built images
- `info` - Show build information

### Image Tags

Images are tagged with both specific versions and `latest`:
- `docker-agent-opencode:1.0.0` and `docker-agent-opencode:latest`
- `docker-agent-opencode:1.0.0-rust` and `docker-agent-opencode:latest-rust`
- `docker-agent-opencode:1.0.0-ruby` and `docker-agent-opencode:latest-ruby`
- `docker-gemini-cli:0.10.0` and `docker-gemini-cli:latest`

## Build Targets

### Applications
- `nix run` - Run OpenCode wrapper (default)
- `nix run .#opencode` - Run default OpenCode wrapper
- `nix run .#opencode-rust` - Run Rust-enabled OpenCode wrapper
- `nix run .#opencode-ruby` - Run Ruby-enabled OpenCode wrapper
- `nix run .#gemini` - Run Gemini CLI wrapper

### Packages
- `nix build .#opencode` - Build default OpenCode wrapper
- `nix build .#opencode-rust` - Build Rust-enabled OpenCode wrapper
- `nix build .#opencode-ruby` - Build Ruby-enabled OpenCode wrapper
- `nix build .#gemini` - Build Gemini CLI wrapper

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
