# Sandbox Agents

`SandboxAgent` gives an agent a persistent workspace — filesystem tools, shell
access and skills — inside an isolated sandbox, so it can search large document
sets, edit files, run commands, generate artifacts and resume from saved state.
The sandbox hosts the tools; the agent loop itself still runs in your process.

**Beta.** The docs say the API, defaults and supported capabilities may change
before general availability. Fetch the current page before writing code:
`https://openai.github.io/openai-agents-python/sandbox_agents/` (Python 3.10+).

## Building blocks (names verified against the docs page)

| Import | Purpose |
|--------|---------|
| `from agents.sandbox import SandboxAgent, SandboxRunConfig, Manifest` | The agent type, the per-run sandbox config, and the workspace manifest (what gets mounted) |
| `from agents.sandbox.entries import LocalDir` | Manifest entry that mounts a local directory into the workspace |
| `from agents.sandbox.capabilities import Capabilities` | Tool bundle inside the sandbox — start from `Capabilities.default()` and add e.g. `Skills` |
| `from agents.sandbox.sandboxes.unix_local import UnixLocalSandboxClient` | Runs the sandbox on the local Unix machine |
| `DockerSandboxClient` | Container-backed sandbox; install with `pip install "openai-agents[docker]"` |
| `from agents import Runner, RunConfig` | Run as usual: `RunConfig(sandbox=SandboxRunConfig(client=...))` |

Shape of a run (fill in from the docs' example — do not guess constructor
arguments):

```python
from agents import Runner, RunConfig
from agents.sandbox import SandboxAgent, SandboxRunConfig, Manifest
from agents.sandbox.entries import LocalDir
from agents.sandbox.capabilities import Capabilities
from agents.sandbox.sandboxes.unix_local import UnixLocalSandboxClient

agent = SandboxAgent(
    name="Workspace agent",
    instructions="Work inside the mounted workspace.",
    default_manifest=Manifest(entries=[LocalDir(...)]),   # see docs for LocalDir args
    default_capabilities=Capabilities.default(),         # add Skills(...) if the workspace ships skills
)

result = await Runner.run(
    agent,
    "Summarize the docs folder",
    run_config=RunConfig(sandbox=SandboxRunConfig(client=UnixLocalSandboxClient())),
)
```

## Resuming state

`SandboxRunConfig` accepts a `session`, `session_state` or `snapshot` so a later
run picks up the same workspace instead of starting cold. Skills can be loaded
lazily from a directory with `LocalDirLazySkillSource`. Details, snapshot
semantics and the compaction behaviour are only in the live docs — quote them,
do not reconstruct from memory.

## When not to use it

- The task is a plain tool call or API orchestration — `@function_tool` is
  enough and has no sandbox overhead.
- You need delegation: there is no separate `Subagent` class; compose with
  `agent.as_tool()` or handoffs (see handoffs.md, tools.md).
