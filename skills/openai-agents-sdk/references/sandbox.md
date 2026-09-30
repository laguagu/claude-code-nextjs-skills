# Sandbox agents (beta)

Use `SandboxAgent` when the agent needs a persistent workspace: files, shell,
lazily loaded skills. Plain function tools need no workspace runtime. The
sandbox hosts tool execution; the agent loop stays in your process. The API is
beta: read the installed `agents/sandbox/` source or the official
[sandbox quickstart](https://openai.github.io/openai-agents-python/sandbox_agents/)
before choosing clients, capabilities, manifests or mounts.

| Import | Role |
| --- | --- |
| `from agents.sandbox import SandboxAgent, SandboxRunConfig, Manifest` | Agent, per-run config, workspace manifest |
| `from agents.sandbox.entries import LocalDir, LocalFile, Dir` | Copy host files in, or create a workspace dir |
| `from agents.sandbox.capabilities import Capabilities, Skills, LocalDirLazySkillSource` | Sandbox tools (`Capabilities.default()`) and skills |
| `from agents.sandbox.sandboxes.unix_local import UnixLocalSandboxClient` | Host processes |
| `from agents.sandbox.sandboxes.docker import DockerSandboxClient` | Container (`openai-agents[docker]`) |

Run with `RunConfig(sandbox=SandboxRunConfig(client=...))`.

- `UnixLocalSandboxClient` adds no OS confinement on Linux; on macOS
  `sandbox-exec` restricts the filesystem but not the network. For untrusted or
  input-influenced commands use Docker, a hosted client or external isolation.
- Since 0.17, `LocalDir`/`LocalFile` sources outside the process working
  directory need `Manifest(extra_path_grants=(SandboxPathGrant(path=..., read_only=True),))`.
  Never build grants from model output.
- Resume through `SandboxRunConfig(session=...)`, `session_state=` or
  `snapshot=`. Define who owns cleanup and what persists.
- Skills are instructions; loading them grants no tools or isolation.

Verify on the target host: cancellation, cleanup, resume and access limits.
`agents.testing.scripted_sandbox_session()` tests the workflow without starting
a sandbox.
