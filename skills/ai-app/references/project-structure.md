# Project Structure

Standard directory layout for AI applications.

## Basic Structure

```
my-ai-app/
├── app/                         # Next.js App Router
│   ├── page.tsx                 # Main UI (chat/dashboard)
│   ├── layout.tsx               # Root layout
│   ├── globals.css              # Theme & global styles
│   └── api/
│       └── chat/
│           └── route.ts         # AI API endpoint
├── components/
│   ├── ai-elements/             # AI Elements (installed)
│   │   ├── conversation.tsx
│   │   ├── message.tsx
│   │   ├── prompt-input.tsx
│   │   ├── reasoning.tsx
│   │   ├── sources.tsx
│   │   ├── tool.tsx
│   │   └── loader.tsx
│   └── ui/                      # shadcn/ui components
│       ├── button.tsx
│       ├── input.tsx
│       └── ...
├── lib/
│   └── utils.ts                 # cn() utility
├── .env.local                   # API keys
├── next.config.ts               # Next.js config
├── tailwind.config.ts           # Tailwind config
├── components.json              # shadcn/ui config
└── package.json
```

## With Agents

```
my-ai-app/
├── app/
│   ├── page.tsx
│   ├── layout.tsx
│   ├── globals.css
│   └── api/
│       └── chat/
│           └── route.ts
├── ai/                          # Agent definitions
│   ├── assistant.ts             # Main assistant
│   ├── research.ts              # Research agent
│   └── code.ts                  # Code agent
├── components/
│   ├── ai-elements/
│   └── ui/
├── lib/
│   ├── utils.ts
│   └── ai.ts                    # AI configuration (optional)
└── ...
```

## Multi-Page App

```
my-ai-app/
├── app/
│   ├── page.tsx                 # Landing/home
│   ├── layout.tsx
│   ├── globals.css
│   ├── (chat)/                  # Chat route group
│   │   ├── chat/
│   │   │   └── page.tsx         # Chat UI
│   │   └── layout.tsx           # Chat layout
│   ├── (dashboard)/             # Dashboard route group
│   │   ├── dashboard/
│   │   │   └── page.tsx         # Dashboard UI
│   │   └── layout.tsx           # Dashboard layout
│   └── api/
│       └── chat/
│           └── route.ts
├── components/
│   ├── ai-elements/
│   ├── ui/
│   ├── chat/                    # Chat-specific components
│   │   └── chat-messages.tsx
│   └── dashboard/               # Dashboard-specific components
│       └── agent-selector.tsx
├── ai/                          # Agent definitions
├── lib/
└── ...
```

## File Purposes

### Core Files

| File | Purpose |
|------|---------|
| `app/page.tsx` | Main application UI |
| `app/layout.tsx` | Root layout with providers |
| `app/globals.css` | CSS variables, Tailwind base |
| `app/api/chat/route.ts` | AI streaming endpoint |

### Configuration

| File | Purpose |
|------|---------|
| `.env.local` | API keys (not committed) |
| `next.config.ts` | Next.js configuration |
| `tailwind.config.ts` | Tailwind theme |
| `components.json` | shadcn/ui settings |

### Components

| Directory | Purpose |
|-----------|---------|
| `components/ai-elements/` | AI Elements (from CLI) |
| `components/ui/` | shadcn/ui primitives |
| `components/chat/` | Chat-specific components |
| `components/dashboard/` | Dashboard components |

### Agents

| File | Purpose |
|------|---------|
| `ai/[name].ts` | Individual agent definitions (use `@/ai/assistant` imports) |

### Utilities

| File | Purpose |
|------|---------|
| `lib/utils.ts` | cn() and common utilities |
| `lib/ai.ts` | AI configuration (optional) |

## Environment Variables

```bash
# .env.local - Choose your provider(s)

# Anthropic (Claude)
ANTHROPIC_API_KEY=sk-ant-...

# OpenAI (GPT-4, etc.)
OPENAI_API_KEY=sk-...

# Google Generative AI (Gemini)
GOOGLE_GENERATIVE_AI_API_KEY=...

# Perplexity (web search)
PERPLEXITY_API_KEY=pplx-...
```

## Package.json Scripts

```json
{
  "scripts": {
    "dev": "bun --bun next dev",
    "build": "bun --bun next build",
    "start": "bun --bun next start",
    "lint": "next lint"
  }
}
```

## Dependencies

### Required

```json
{
  "dependencies": {
    "ai": "latest",
    "@ai-sdk/react": "latest",
    "@ai-sdk/anthropic": "latest",
    "zod": "latest",
    "next": "latest",
    "react": "latest",
    "react-dom": "latest"
  }
}
```

### Optional Dependencies

```json
{
  "dependencies": {
    "@ai-sdk/perplexity": "latest",
    "mathjs": "latest"
  }
}
```

- `@ai-sdk/perplexity` - Web search chatbot (Perplexity provider)
- `mathjs` - Safe math expression evaluation for calculator tools

### AI Elements Dependencies

Installed automatically with `bunx --bun ai-elements@latest`:

- `use-stick-to-bottom` - Auto-scroll
- `streamdown` - Markdown streaming
- `shiki` - Syntax highlighting (for CodeBlock)
- `motion` - Animations (for Shimmer)
- `@xyflow/react` - Canvas/workflow (optional)

## Best Practices

1. **Keep agents separate** - One file per agent in `ai/`
2. **Use route groups** - `(chat)/`, `(dashboard)/` for organization
3. **Extract components** - Move complex UI to `components/chat/`
4. **Environment safety** - Never commit `.env.local`
5. **Type safety** - Use `InferAgentUIMessage` for typed messages
