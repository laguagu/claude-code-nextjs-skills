# AI Elements and AI SDK integration

Use this for the boundary between chat state, generated components and server
responses. This is a contract reference, not a copyable application template.

## Match the versions

Resolve `ai`, `@ai-sdk/react`, provider packages and generated AI Elements
source first. Use `ai-sdk-6` for an existing v6 project and `ai-sdk-7` for v7.
Read installed SDK types and version-matched docs before composing the transport,
response helper or lifecycle callbacks.

For v6, `convertToModelMessages` is asynchronous; await it before passing its
result as model messages. The
[v6 migration guide](https://ai-sdk.dev/docs/migration-guides/migration-guide-6-0)
documents this change. Do not transplant v7 helpers into v6 without migration.

## Own the message contract

Import SDK message and part types instead of recreating a partial union. UI
messages and model messages serve different boundaries. Validate incoming UI
messages, including tool/data schemas where applicable, before conversion.

In v6, tool UI parts use `tool-<name>` or `dynamic-tool` and carry lifecycle
state; `tool-invocation` and `tool-result` are not substitute v6 UI part
definitions. Narrow each part before reading its state, input, output or error.
Render dynamic tools as well as statically named tools when the application
supports them.

Keep one message container per message, with stable identity, and compose its
parts inside it. Match generated component props rather than assuming every
tool part exposes `toolName` or every source supports the same props.

## Server and browser responsibilities

Authorize each conversation and mutation. Keep credentials, provider selection
and tool permissions server-side. A model identifier from the browser needs a
server-side allowlist; a TypeScript assertion on request JSON is not validation.

Use the chosen SDK major's UI stream protocol and transport. Include reasoning
or sources only when the provider returns them and the product should display
them. Keep cancellation, retries, approval decisions and persistence consistent
with that protocol; controls must affect the actual request.

Check how the generated prompt input serializes attachments. Local blob URLs
need conversion or upload before a remote server can consume them. Validate
file type, size and access, and handle missing or failed uploads.

## Verify the interaction

Exercise streamed text, tool progress/error, retry, cancellation and the
attachment path affected by the work. Check message identity after persistence
or refresh, scrolling during streaming, keyboard operation and mobile wrapping.
Use the application's existing provider setup; this component skill does not
choose a provider or prescribe a billing plan.
