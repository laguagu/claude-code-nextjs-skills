---
title: Use Activity Component for Show/Hide
impact: MEDIUM
impactDescription: preserves state/DOM without re-mount cost
tags: rendering, activity, visibility, state-preservation
requires: React 19.2+
---

## Use Activity Component for Show/Hide

Use React's `<Activity>` to preserve state/DOM for expensive components that
frequently toggle visibility. `<Activity>` is stable since React 19.2.

**Why not `{show && <Component />}`?**

- Unmounts the subtree → loses component state
- Re-runs effects on every mount
- Rebuilds DOM on every show

**Why not `display: none`?**

- Effects still run (setInterval, fetch, subscriptions waste resources)
- Doesn't signal React that the subtree is inactive

**Incorrect (loses state and re-runs effects):**

```tsx
function App() {
  const [tab, setTab] = useState<'a' | 'b'>('a')
  return tab === 'a' ? <ExpensiveChartA /> : <ExpensiveChartB />
  // Switching tabs unmounts — scroll position, form state, subscriptions all reset
}
```

**Correct (preserves state, pauses effects when hidden):**

```tsx
import { Activity } from 'react'

function App() {
  const [tab, setTab] = useState<'a' | 'b'>('a')
  return (
    <>
      <Activity mode={tab === 'a' ? 'visible' : 'hidden'}>
        <ExpensiveChartA />
      </Activity>
      <Activity mode={tab === 'b' ? 'visible' : 'hidden'}>
        <ExpensiveChartB />
      </Activity>
    </>
  )
}
```

**Behavior of `hidden` mode:**

- Children render to DOM but are not displayed
- Effects cleanup when mode switches to `'hidden'`
- Effects re-run when mode switches back to `'visible'`
- State (`useState`, refs, uncontrolled inputs) is preserved across toggles

**When to use:**

- Tab panels where users return to the same tab
- Modal/drawer content that's expensive to mount
- Off-screen navigation views in mobile apps
- Any subtree where you want to pay mount cost once

**When NOT to use:**

- Single-use content (e.g. one-time tooltips)
- Very large subtrees where accumulated DOM becomes a memory problem
- Lists where entries come and go permanently

Reference: [React docs: `<Activity>`](https://react.dev/reference/react/Activity)
