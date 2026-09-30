# AI Elements and AI SDK integration

Use this for the boundary between chat state, generated components and server
responses. This is a contract reference, not a copyable application template.

## Match the versions

Resolve `ai`, `@ai-sdk/react`, provider packages and generated AI Elements
source first. Use `ai-sdk-6` for an existing v6 project and `ai-sdk-7` for v7.
Read installed SDK types and version-matched docs before composing the transport,
response helper or lifecycle callbacks.

Model selectors and server examples are illustrative. For current IDs and
capabilities, use the [OpenAI model catalog](https://developers.openai.com/api/docs/models)
and the [AI Gateway catalog](https://vercel.com/ai-gateway/models) for the actual
provider route. `openai/gpt-6.1-sol` was verified in Vercel's catalog on
2026-09-30; select from the application's supported models rather than treating
the demo selection as a production default.

Upstream AI Elements (main at 6a9d5b1) still declares `ai` ^6 and
`@ai-sdk/react` ^3. Against AI SDK 7 types, the generated `context.tsx` fails
typecheck: it reads `usage.reasoningTokens` and `usage.cachedInputTokens`,
which v7's `LanguageModelUsage` moved to `outputTokenDetails.reasoningTokens`
and `inputTokenDetails.cacheReadTokens`. Update those reads in the installed
copy.

`convertToModelMessages` is asynchronous in v6 and v7; await it.
`createAgentUIStreamResponse({ agent, uiMessages })` validates against the
agent tools and converts messages itself. Do not transplant v7 helpers into
v6 without migration.

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
tool part exposes `toolName` or every source supports the same props. The
bundled `ToolHeader` takes `type` and `state`, plus `toolName` only for
`dynamic-tool` parts.

## Server and browser responsibilities

Authorize each conversation and mutation. Keep credentials, provider selection
and tool permissions server-side. A model identifier from the browser needs a
server-side allowlist; a TypeScript assertion on request JSON is not validation.

Use the chosen SDK major's UI stream protocol and transport. Include reasoning
or sources only when the provider returns them and the product should display
them; the SDK's UI stream helpers send reasoning by default but sources only
with `sendSources: true`, so an empty `Sources` block may be a server option.
Keep cancellation, retries, approval decisions and persistence consistent with
that protocol; controls must affect the actual request.

The bundled `Confirmation` renders controls for `approval-requested` parts.
In v7, skip those controls when `part.approval.isAutomatic` is true.

The bundled `PromptInput` converts `blob:` URLs to data URLs before `onSubmit`,
retaining the blob URL if conversion fails. Handle that failure before sending;
a remote server cannot consume a browser-local URL. Attachments otherwise
travel inline. `accept`, `maxFiles` and `maxFileSize` are client-side checks:
validate type, size and access on the server; upload large files separately.

## Verify the interaction

Exercise streamed text, tool progress/error, retry, cancellation and the
attachment path affected by the work. Check message identity after persistence
or refresh, scrolling during streaming, keyboard operation and mobile wrapping.
Use the application's existing provider setup; this component skill does not
choose a provider or prescribe a billing plan.
