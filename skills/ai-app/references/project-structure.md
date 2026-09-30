# Application boundaries

Follow the repository's existing structure. Separate server model/tool execution
from client rendering; share inferred message and tool types through type-only
imports. Keep credentials and server dependencies out of client bundles.

Use the existing route conventions, aliases, UI directories and theme. Let the
shadcn/AI Elements CLI resolve dependencies from the components actually added;
a generic dependency list becomes stale.

Layouts preserve shared UI and state; templates remount their subtree on
navigation. Choose the boundary that matches conversation continuity instead of
resetting chats accidentally. See [Next.js templates](https://nextjs.org/docs/app/api-reference/file-conventions/template).

A larger app may separate agents, tools, storage and chat components when those
modules have distinct responsibilities. A small app does not need that tree.
