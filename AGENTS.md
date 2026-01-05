# AI Agent Guide for Container SELinux Development

This document is specifically designed for AI coding assistants (like Claude, ChatGPT, Copilot) to provide context and guidance when helping developers with container-selinux-related tasks. It contains essential information about policy structure, development patterns, testing frameworks, and common pitfalls that AI agents should be aware of when assisting with SELinux policy development, debugging, and contributions.

## Project Overview

**container-selinux** provides SELinux policy modules that define security policies governing how container runtimes (Podman, Docker, etc.) interact with the host system. It enables secure container operations through mandatory access control policies.

## Quick Start

```bash
# Build and test
make                    # Build policy modules
make man                # Generate man pages (requires installed policy)
sudo make install       # Full install (policy, man pages, templates)

# Development validation
semodule --list=full | grep container   # Check installed modules
sudo semodule -B                        # Rebuild policy
sudo make install-policy                # Install policy only

# Testing
sudo bash test/podman-rootful-tests.sh   # Run rootful tests
sudo bash test/podman-rootless-tests.sh  # Run rootless tests
```

## Codebase Structure

```text
container-selinux/
├── container.te                  # Type Enforcement: Security rules, domains, booleans
├── container.if                  # Interface: Modular policy interfaces
├── container.fc                  # File Context: File path→context mappings
├── container_selinux.8           # Man page source
├── udica-templates/              # CIL templates for Udica
│   ├── base_container.cil        # Base container permissions
│   ├── home_container.cil        # Home directory access
│   ├── net_container.cil         # Network access
│   ├── log_container.cil         # Logging capabilities
│   ├── virt_container.cil        # Virtualization support
│   ├── x_container.cil           # X11/Wayland display access
│   └── ...                       # Other capability templates
├── rpm/
│   └── container-selinux.spec    # RPM package specification
├── test/                         # Test scripts (BATS)
├── .packit.yaml                  # Packit CI/CD configuration
└── Makefile                      # Build and installation targets
```

## Development Patterns

### SELinux Policy Module Components

The three core files work together to define container security policies:

**Type Enforcement (.te)**: Defines security rules
```te
# Define a type for container processes
type container_t;
domain_type(container_t)

# Define a boolean tunable
bool container_connect_any true;

# Create a rule using the boolean
tunable_policy(`container_connect_any',`
    corenet_tcp_connect_all_ports(container_t)
')
```

**Interface (.if)**: Provides reusable policy macros
```te
interface(`container_runtime_exec',`
    gen_require(`
        type container_runtime_exec_t;
    ')
    can_exec($1, container_runtime_exec_t)
')
```

**File Context (.fc)**: Maps files to security contexts
```
/usr/bin/podman         --  gen_context(system_u:object_r:container_runtime_exec_t,s0)
/var/lib/containers(/.*)?   gen_context(system_u:object_r:container_var_lib_t,s0)
```

### Udica CIL Templates

Templates use Common Intermediate Language (CIL) for dynamic policy generation:

```cil
(block base_container
    (blockinherit container)
    (allow process process (capability (chown fowner fsetid ...)))
)
```

## Testing

### BATS Tests

**System Tests** (`test/`): Test SELinux policies with actual Podman containers using the upstream Podman SELinux test suite.

```bash
# Run rootful Podman SELinux tests
sudo bash test/podman-rootful-tests.sh

# Run rootless Podman SELinux tests
sudo bash test/podman-rootless-tests.sh
```

Tests execute `/usr/share/podman/test/system/410-selinux.bats` to verify:
- Container labeling (`:z`, `:Z` volume options)
- Process confinement
- File access controls
- Boolean tunable behavior
- Udica custom policy integration

### Manual Testing Commands

```bash
# Check policy installation
semodule --list=full | grep container

# Verify file contexts
semanage fcontext -l | grep container

# Test boolean tunables
getsebool container_connect_any
sudo setsebool container_connect_any on

# Check container process contexts
ps -eZ | grep container_t

# Verify AVC denials
sudo ausearch -m avc -ts recent | grep container
```

## Code Standards

**Official Documentation**: [README.md](README.md)

- **Policy Language**: SELinux Reference Policy macros and m4 preprocessing
- **CIL Templates**: Common Intermediate Language for Udica templates
- **Version Management**: Use git tags (`v1.2.3`), not spec file Version field
- **Commits**: Must be signed (`git commit -s`)
- **CI/CD**: All PRs run Packit builds and Testing Farm validation

## Platform-Specific Considerations

### RHEL vs Fedora Differences

```spec
# Legacy /var/run for older platforms
%if 0%{?rhel} < 10 || 0%{?fedora} < 40
    /var/run/containerd.sock → /run/containerd.sock
%endif

# User namespace support
%if 0%{?rhel} <= 9
    # Remove user_namespace lines from policy
%endif
```

### COPR Builds

Different Epoch values for `rhcontainerbot/podman-next` builds to handle version downgrades.

## Key SELinux Tunables

Important boolean tunables that control container behavior:

- **`container_connect_any`**: Allow containers to connect to any network port
- **`container_use_devices`**: Allow mounting device volumes (`--device`)
- **`container_read_certs`**: Allow reading certificate files from `/etc/pki`
- **`sshd_launch_containers`**: Allow sshd to launch container engines (rootless SSH)
- **`container_manage_public_content`**: Allow containers to manage public_content_rw_t files
- **`virt_sandbox_use_all_caps`**: Allow virt sandbox containers full capabilities

## Key Tools and Libraries

- **[checkpolicy](https://github.com/SELinuxProject/selinux)**: SELinux policy compiler
- **[libselinux](https://github.com/SELinuxProject/selinux)**: SELinux core library
- **[libsemanage](https://github.com/SELinuxProject/selinux)**: SELinux policy management
- **[Packit](https://packit.dev)**: Automated packaging and CI/CD
- **[selinux-policy](https://github.com/fedora-selinux/selinux-policy)**: Reference policy framework
- **[sepolicy](https://github.com/SELinuxProject/selinux)**: SELinux policy analysis tools
- **[Udica](https://github.com/containers/udica)**: Custom SELinux policy generator for containers

## Common Pitfalls for AI Agents

1. **Never modify Version in spec file** - Use git tags; Packit auto-sets version
2. **Platform differences** - Consider RHEL vs Fedora differences for `/var/run` vs `/run`
3. **Boolean defaults** - Understand when booleans should default to `true` vs `false`
4. **Context inheritance** - Container types may inherit from base domains
5. **AVC denials** - Always check `audit.log` for actual denials before adding rules
6. **Udica integration** - Templates must be valid CIL and coordinate with base policy
7. **Testing scope** - Policy changes require both rootful and rootless testing
8. **Man page sync** - Update `container_selinux.8` when adding/changing booleans

## Essential Commands

```bash
# Policy analysis
seinfo -t | grep container                     # List container types
sesearch -A -s container_t                     # Show rules for container_t
semanage boolean -l | grep container           # List container booleans

# Development
make clean && make                             # Clean rebuild
sudo semodule -r container                     # Remove old module
sudo semodule -i container.pp.bz2              # Install new module
sudo restorecon -Rv /var/lib/containers        # Relabel files

# Debugging
sudo ausearch -m avc -ts recent                # Recent AVC denials
sudo audit2allow -a                            # Suggest rules for denials
sudo setenforce 0                              # Permissive mode (testing only)
sudo semodule -DB                              # Rebuild and disable dontaudit

# Testing
sudo podman run --rm -it --security-opt label=type:container_t fedora:latest
ls -Z /var/lib/containers                      # Verify file contexts
ps -eZ | grep container                        # Verify process contexts
```

## Documentation

- **[CLAUDE.md](CLAUDE.md)**: Project-specific guidance for Claude Code
- **[README.md](README.md)**: Project overview and Dan Walsh's blog references
- **[rpm/container-selinux.spec](rpm/container-selinux.spec)**: Packaging specification
- **[.packit.yaml](.packit.yaml)**: CI/CD configuration
- **[Dan Walsh's Blog](https://danwalsh.livejournal.com/)**: SELinux container concepts
  - Container labeling (`container_t` vs `container_var_lib_t`)
  - Volume relabeling with `:Z` and `:z`
  - MLS (Multi Level Security) support
- **[SELinux Project Wiki](https://github.com/SELinuxProject/selinux/wiki)**: General SELinux development
- **[Udica Documentation](https://github.com/containers/udica)**: Custom policy generation

For comprehensive information, refer to the official documentation and recent commits in the [container-selinux repository](https://github.com/containers/container-selinux).
