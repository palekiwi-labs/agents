# TODO

---

## Env Var Config

Allow configuring the contanier parameters in wrappers (`lib/gemini-wrapper.nix`, `lib/opencode-wrapper.nix`) with environmental variables. Each environmental variable needs to have a default or handle an empty value if not requiEach environmental variable needs to have a default or handle an empty value if not required.

Example variables:

```yaml
# AGENTS
- name: AGENTS_WORKSPACE
  notes: sets the `WORKSPACE` variable, can be overriden by `OPENCODE_WORKSPACE` or `GEMINI_WORKSPACE`

# OPENCODE
- name: OPENCODE_CONTAINER_NAME
  notes: use currently computed value

- name: OPENCODE_PORT
  notes: use currently computed value

- name: OPENCODE_CONFIG_DIR
  default: "$HOME/.config/agent-opencode"

- name: OPENCODE_NETWORK
  default: bridge

- name: OPENCODE_MEMORY
  default: 1024m

- name: OPENCODE_CPUS
  default: 1.0

- name: OPENCODE_PIDS_LIMIT
  default: 100

# GEMINI
- name: GEMINI_CONTAINER_NAME
  notes: use currently computed value

- name: GEMINI_CONFIG_DIR
  default: "$HOME/.config/agent-gemini-cli"

- name: GEMINI_NETWORK
  default: bridge

- name: GEMINI_MEMORY
  default: 1024m

- name: GEMINI_CPUS
  default: 1.0

- name: GEMINI_PIDS_LIMIT
  default: 100
```
