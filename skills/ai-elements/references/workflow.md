# Workflow Components

Visual workflow/canvas components built on React Flow.

## Installation

```bash
bun add @xyflow/react
```

## Canvas

React Flow wrapper with sensible defaults.

```tsx
import { Canvas } from '@/components/ai-elements/canvas';
import { Controls } from '@/components/ai-elements/controls';
import { Panel } from '@/components/ai-elements/panel';

<Canvas
  nodes={nodes}
  edges={edges}
  onNodesChange={onNodesChange}
  onEdgesChange={onEdgesChange}
  nodeTypes={nodeTypes}
  edgeTypes={edgeTypes}
>
  <Controls />
  <Panel position="top-right">
    <Button>Add Node</Button>
  </Panel>
</Canvas>
```

### Default Configuration

| Feature | Value |
|---------|-------|
| Delete keys | Backspace, Delete |
| Fit view | Enabled |
| Pan on drag | Disabled |
| Pan on scroll | Enabled |
| Selection drag | Enabled |
| Zoom on double-click | Disabled |
| Background | `var(--sidebar)` |

## Node

Card-based workflow node with handles.

```tsx
import {
  Node,
  NodeHeader,
  NodeTitle,
  NodeDescription,
  NodeContent,
  NodeFooter,
  NodeAction,
} from '@/components/ai-elements/node';

// Define custom node component
function MyNode({ data }) {
  return (
    <Node handles={{ target: true, source: true }}>
      <NodeHeader>
        <NodeTitle>{data.title}</NodeTitle>
        <NodeDescription>{data.description}</NodeDescription>
        <NodeAction>
          <Button size="icon-sm" variant="ghost">
            <SettingsIcon className="size-4" />
          </Button>
        </NodeAction>
      </NodeHeader>
      <NodeContent>
        {data.content}
      </NodeContent>
      <NodeFooter>
        <Badge>{data.status}</Badge>
      </NodeFooter>
    </Node>
  );
}

// Register node type
const nodeTypes = {
  custom: MyNode,
};
```

### Props

| Component | Props |
|-----------|-------|
| `Node` | `handles: { target: boolean; source: boolean }` |
| `NodeHeader` | Styled header with `bg-secondary` |
| `NodeTitle` | Title text |
| `NodeDescription` | Muted description |
| `NodeAction` | Action button slot (top-right) |
| `NodeContent` | Main content area |
| `NodeFooter` | Footer with `bg-secondary` |

### Handle Positions

- **Target** (input): Left side (`Position.Left`)
- **Source** (output): Right side (`Position.Right`)

## Edge

Two edge types for different states.

```tsx
import { Edge } from '@/components/ai-elements/edge';

const edgeTypes = {
  temporary: Edge.Temporary,
  animated: Edge.Animated,
};

// Usage in Canvas
<Canvas
  edges={[
    { id: 'e1', source: 'a', target: 'b', type: 'animated' },
    { id: 'e2', source: 'b', target: 'c', type: 'temporary' },
  ]}
  edgeTypes={edgeTypes}
/>
```

### Edge Types

| Type | Description | Style |
|------|-------------|-------|
| `Edge.Temporary` | Connection preview | Dashed, simple bezier |
| `Edge.Animated` | Active connection | Solid, animated circle traveling along path |

## Connection

Custom connection line component for drag preview.

```tsx
import { Connection } from '@/components/ai-elements/connection';

<Canvas
  connectionLineComponent={Connection}
/>
```

## Controls

Zoom and fit view controls.

```tsx
import { Controls } from '@/components/ai-elements/controls';

<Canvas>
  <Controls
    showZoom={true}
    showFitView={true}
    showInteractive={false}
  />
</Canvas>
```

## Panel

Positioned overlay for custom UI.

```tsx
import { Panel } from '@/components/ai-elements/panel';

<Canvas>
  <Panel position="top-left">
    <h2>Workflow Title</h2>
  </Panel>
  <Panel position="top-right">
    <Button>Save</Button>
  </Panel>
  <Panel position="bottom-center">
    <Toolbar>...</Toolbar>
  </Panel>
</Canvas>
```

### Positions

- `top-left`, `top-center`, `top-right`
- `bottom-left`, `bottom-center`, `bottom-right`

## Context

Token usage tracking display with cost calculation.

```tsx
import {
  Context,
  ContextTrigger,
  ContextContent,
  ContextContentHeader,
  ContextContentBody,
  ContextContentFooter,
  ContextInputUsage,
  ContextOutputUsage,
  ContextReasoningUsage,
  ContextCacheUsage,
} from '@/components/ai-elements/context';

<Context
  usedTokens={15000}
  maxTokens={128000}
  modelId="claude-3-5-sonnet-20241022"
  usage={{
    inputTokens: 10000,
    outputTokens: 5000,
    reasoningTokens: 2000,
    cachedInputTokens: 3000,
  }}
>
  <ContextTrigger />
  <ContextContent>
    <ContextContentHeader />
    <ContextContentBody>
      <ContextInputUsage />
      <ContextOutputUsage />
      <ContextReasoningUsage />
      <ContextCacheUsage />
    </ContextContentBody>
    <ContextContentFooter />
  </ContextContent>
</Context>
```

### Props

| Prop | Type | Description |
|------|------|-------------|
| `usedTokens` | `number` | Total tokens used |
| `maxTokens` | `number` | Context window size |
| `modelId` | `string` | Model ID for cost calculation |
| `usage` | `LanguageModelUsage` | AI SDK usage object |

### Features

- Circular progress indicator
- Percentage display
- Compact number formatting
- Cost calculation via `tokenlens`
- Breakdown by input/output/reasoning/cache

## Complete Workflow Example

```tsx
'use client';

import { useState, useCallback } from 'react';
import { Canvas } from '@/components/ai-elements/canvas';
import { Node, NodeHeader, NodeTitle, NodeContent } from '@/components/ai-elements/node';
import { Edge } from '@/components/ai-elements/edge';
import { Controls } from '@/components/ai-elements/controls';
import { Panel } from '@/components/ai-elements/panel';
import {
  useNodesState,
  useEdgesState,
  addEdge,
  type Connection,
} from '@xyflow/react';

function AgentNode({ data }) {
  return (
    <Node handles={{ target: true, source: true }}>
      <NodeHeader>
        <NodeTitle>{data.label}</NodeTitle>
      </NodeHeader>
      <NodeContent>
        <p className="text-sm text-muted-foreground">{data.description}</p>
      </NodeContent>
    </Node>
  );
}

const nodeTypes = { agent: AgentNode };
const edgeTypes = { animated: Edge.Animated };

const initialNodes = [
  { id: '1', type: 'agent', position: { x: 0, y: 0 }, data: { label: 'Input', description: 'User query' } },
  { id: '2', type: 'agent', position: { x: 300, y: 0 }, data: { label: 'Process', description: 'AI processing' } },
  { id: '3', type: 'agent', position: { x: 600, y: 0 }, data: { label: 'Output', description: 'Response' } },
];

const initialEdges = [
  { id: 'e1-2', source: '1', target: '2', type: 'animated' },
  { id: 'e2-3', source: '2', target: '3', type: 'animated' },
];

export function WorkflowEditor() {
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);

  const onConnect = useCallback(
    (connection: Connection) => setEdges((eds) => addEdge({ ...connection, type: 'animated' }, eds)),
    [setEdges]
  );

  return (
    <div className="h-screen w-full">
      <Canvas
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        nodeTypes={nodeTypes}
        edgeTypes={edgeTypes}
      >
        <Controls />
        <Panel position="top-right">
          <Button onClick={() => console.log(nodes, edges)}>
            Export
          </Button>
        </Panel>
      </Canvas>
    </div>
  );
}
```

## Dependencies

- `@xyflow/react` - React Flow library
- `tokenlens` - Token cost calculation (for Context component)
