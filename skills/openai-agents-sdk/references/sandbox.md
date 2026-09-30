# Sandbox agents

Use `SandboxAgent` when the agent needs a persistent workspace, filesystem/shell
tools or lazily loaded skills. Ordinary API/function-tool work need not pay for
a workspace runtime.

The sandbox hosts execution; the agent loop remains in the application process.
The API is beta. Read the current
[sandbox quickstart](https://openai.github.io/openai-agents-python/sandbox_agents/)
and installed source before choosing clients, capabilities, manifests or mounts.

A local Unix client, Docker client and remote environment do not establish the
same isolation/permission boundary. `UnixLocalSandboxClient` adds no OS
confinement on Linux; its macOS `sandbox-exec` filesystem restrictions do not
isolate the network (verified in 0.22.3). Use a suitably isolated backend for
untrusted commands. Configure allowed paths, commands, network access and
credentials for the task; do not copy demo defaults blindly.

Use documented session/snapshot state to resume the workspace. Define who owns
cleanup and how mounts or files persist. Skills are instruction bundles;
loading them does not authorize tools or grant isolation.

Verify the actual client on the target host, including cancellation, cleanup,
resume and access limits. Do not show an incomplete constructor sketch as a
working example. `agents.testing.scripted_sandbox_session()` supports offline
workflow tests without starting a sandbox (verified in 0.22.3).
