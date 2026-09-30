# AI Elements and AI SDK integration

The boundary between chat state, generated components and server responses.

## Match the versions

Resolve `ai`, `@ai-sdk/react`, provider packages and generated AI Elements
source first. Use `ai-sdk-6` for an existing v6 project and `ai-sdk-7` for v7.
Read installed SDK types and `node_modules/ai/docs/` before composing the
transport, response helper or lifecycle callbacks; do not transplant v7
helpers into v6 without migration.

`convertToModelMessages` is async in v6 and v7; await it.
`createAgentUIStreamResponse` validates and converts `uiMessages` itself.

## Own the message contract

Import SDK message and part types instead of recreating a partial union. UI
messages and model messages serve different boundaries. Validate incoming UI
messages, including tool/data schemas where applicable, before conversion.

Tool UI parts are `tool-<name>` or `dynamic-tool` and carry lifecycle state;
`tool-invocation` and `tool-result` are obsolete part types. Narrow each part
before reading its state, input, output or error. The generated `ToolHeader`
takes `type` and `state`, plus `toolName` for `dynamic-tool` parts only.

Keep one message container per message, with stable identity, and compose its
parts inside it. Match generated component props rather than assuming every
source or tool component accepts the same props.

## Server and browser responsibilities

Authorize each conversation and mutation. Keep credentials, provider selection
and tool permissions server-side. A model identifier from the browser needs a
server-side allowlist; a TypeScript assertion on request JSON is not validation.

Use the chosen SDK major's UI stream protocol and transport. UI streams send
reasoning by default (`sendReasoning: true`) but not sources
(`sendSources: false`); set them for what the product should display. Keep
cancellation, retries, approval decisions and persistence consistent with that
protocol; controls must affect the actual request.

The generated `Confirmation` shows its request and actions for any
`approval-requested` part. In v7, automatic policy decisions also pass through
that state with `approval.isAutomatic: true`; skip the controls for those.

`PromptInput` converts `blob:` URLs to data URLs before `onSubmit` (keeping the
blob URL if conversion fails), so `sendMessage({ text, files })` sends files
inline in the request. Its `accept`, `maxFiles` and `maxFileSize` checks are
client-side only: validate type, size and access on the server, and upload
large files instead of inlining them.

## Verify the interaction

Exercise streamed text, tool progress/error, retry, cancellation and the
attachment path affected by the work. Check message identity after persistence
or refresh, scrolling during streaming, keyboard operation and mobile wrapping.
