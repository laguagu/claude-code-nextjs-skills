# RSC Boundaries

Detect and prevent invalid patterns when crossing Server/Client component boundaries.

## Detection Rules

### 1. Async Client Components Are Invalid

Client components **cannot** be async functions. Only Server Components can be async.

**Detect:** File has `'use client'` AND component is `async function` or returns `Promise`

```tsx
// Bad: async client component
'use client'
export default async function UserProfile() {
  const user = await getUser() // Cannot await in client component
  return <div>{user.name}</div>
}

// Good: Remove async, fetch data in parent server component
// page.tsx (server component - no 'use client')
export default async function Page() {
  const user = await getUser()
  return <UserProfile user={user} />
}

// UserProfile.tsx (client component)
'use client'
export function UserProfile({ user }: { user: User }) {
  return <div>{user.name}</div>
}
```

```tsx
// Bad: async arrow function client component
'use client'
const Dashboard = async () => {
  const data = await fetchDashboard()
  return <div>{data}</div>
}

// Good: Fetch in server component, pass data down
```

### 2. Non-Serializable Props to Client Components

Props passed from Server → Client must be serializable by React's Server
Components serialization (this is **broader than JSON** — see the
[`'use client'` reference](https://react.dev/reference/rsc/use-client#serializable-types)).

**Serializable (safe to pass):** `string`, `number`, `bigint`, `boolean`,
`undefined`, `null`, globally-registered symbols (`Symbol.for`), `Array`,
`Map`, `Set`, `TypedArray`, `ArrayBuffer`, **`Date`**, plain objects,
Promises, JSX elements, and Server Functions (`'use server'`).

**Detect (NOT serializable):** Server component passes these to a client component:
- Functions that are not Server Actions and not exported from a client module
- Class instances (and objects with a `null` prototype)
- `WeakMap`, `WeakSet`
- Non-global symbols (e.g. `Symbol('x')`)

> **Note:** `Date`, `Map`, and `Set` **are** serializable across the boundary —
> you do not need to convert them. The only common footguns are functions and
> class instances.

```tsx
// Bad: Function prop
// page.tsx (server)
export default function Page() {
  const handleClick = () => console.log('clicked')
  return <ClientButton onClick={handleClick} />
}

// Good: Define function inside client component
// ClientButton.tsx
'use client'
export function ClientButton() {
  const handleClick = () => console.log('clicked')
  return <button onClick={handleClick}>Click</button>
}
```

```tsx
// OK: Date is serializable - pass it directly, it arrives as a Date
// page.tsx (server)
export default async function Page() {
  const post = await getPost()
  return <PostCard createdAt={post.createdAt} /> // Date object - fine
}

// PostCard.tsx (client) - receives a real Date
'use client'
export function PostCard({ createdAt }: { createdAt: Date }) {
  return <span>{createdAt.getFullYear()}</span> // Works
}
```

```tsx
// OK: Map/Set are serializable too - no conversion needed
<ClientComponent items={new Map([['a', 1]])} />
<ClientComponent tags={new Set(['a', 'b'])} />
```

```tsx
// Bad: Class instance (methods/prototype are lost)
const user = new UserModel(data)
<ClientProfile user={user} /> // Not serializable

// Good: Pass plain object
const user = await getUser()
<ClientProfile user={{ id: user.id, name: user.name }} />
```

### 3. Server Actions Are the Exception

Functions marked with `'use server'` CAN be passed to client components.

```tsx
// Valid: Server Action can be passed
// actions.ts
'use server'
export async function submitForm(formData: FormData) {
  // server-side logic
}

// page.tsx (server)
import { submitForm } from './actions'
export default function Page() {
  return <ClientForm onSubmit={submitForm} /> // OK!
}

// ClientForm.tsx (client)
'use client'
export function ClientForm({ onSubmit }: { onSubmit: (data: FormData) => Promise<void> }) {
  return <form action={onSubmit}>...</form>
}
```

## Quick Reference

| Pattern | Valid? | Fix |
|---------|--------|-----|
| `'use client'` + `async function` | No | Fetch in server parent, pass data |
| Pass `() => {}` to client | No | Define in client or use server action |
| Pass class instance to client | No | Pass plain object |
| Pass `new WeakMap()`/`WeakSet()` | No | Convert to array/object |
| Pass `Symbol('x')` (non-global) | No | Use `Symbol.for('x')` or a string |
| Pass `new Date()` to client | Yes | - (serializable, arrives as `Date`) |
| Pass `new Map()`/`new Set()` | Yes | - (serializable) |
| Pass server action to client | Yes | - |
| Pass `string/number/bigint/boolean` | Yes | - |
| Pass plain object/array/Promise | Yes | - |
