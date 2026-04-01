# Popup Widget Pattern

Floating chat button that opens a popup panel — embeddable on any site via `<script>` tag or iframe.

## Architecture

Three components work together:

```
ChatButton (fixed FAB, bottom-right)
  ↕ toggleOpen
ChatContainer (fixed 400×600 popup, spring animation)
  └── ChatPanel (header + content)
ChatWidget (state management, renders chatContent into Container)
```

## ChatButton

Floating action button with Lottie callout for first-time visitors.

```tsx
// components/chat/chat-button.tsx
"use client";

import { memo, useState, useEffect } from "react";
import { motion } from "motion/react";
import { MessageCircle, X } from "lucide-react";
import { ChatCallout } from "./chat-callout"; // Lottie "How can I help?" bubble

export const ChatButton = memo(({ isOpen, onClick }: { isOpen: boolean; onClick: () => void }) => (
  <div className="fixed bottom-6 right-6 z-50 flex items-end gap-3">
    <ChatCallout isOpen={isOpen} />
    <motion.button
      onClick={onClick}
      className="relative flex h-14 w-14 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-lg"
      whileTap={{ scale: 0.95 }}
      initial={{ scale: 0, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      transition={{ type: "spring", stiffness: 260, damping: 20 }}
    >
      <motion.div animate={{ rotate: isOpen ? 90 : 0 }} transition={{ duration: 0.2 }}>
        {isOpen ? <X size={24} /> : <MessageCircle size={24} />}
      </motion.div>
    </motion.button>
  </div>
));
```

## ChatContainer

Popup panel with spring animation. Desktop: fixed 400×600. Mobile: fullscreen.

```tsx
// components/chat/chat-container.tsx
import { AnimatePresence, motion } from "motion/react";

export const ChatContainer = memo(({ isOpen, onClose, children }) => (
  <AnimatePresence>
    {isOpen && (
      <motion.div
        className="fixed z-50 bottom-24 right-6 h-[600px] w-[400px]
                   max-sm:bottom-0 max-sm:right-0 max-sm:left-0 max-sm:top-0 max-sm:h-full max-sm:w-full"
        initial={{ opacity: 0, y: 20, scale: 0.95 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 20, scale: 0.95 }}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
      >
        <div className="flex h-full min-h-0 flex-col overflow-hidden rounded-xl max-sm:rounded-none
                        border border-border bg-background shadow-2xl">
          {/* Header with logo + close button */}
          <div className="flex items-center justify-between border-b px-4 py-2.5 bg-card">
            {/* Logo + title */}
            <Button variant="ghost" size="icon" onClick={onClose}>
              <X size={16} />
            </Button>
          </div>
          {/* Content fills remaining space */}
          <div className="flex-1 min-h-0 overflow-hidden">{children}</div>
        </div>
      </motion.div>
    )}
  </AnimatePresence>
));
```

## ChatWidget with popup + inline modes

```tsx
export function ChatWidget({ inline = false }: { inline?: boolean }) {
  const [isOpen, setIsOpen] = useState(false);

  const chatContent = (
    <div className="flex h-full min-h-0 flex-col">
      <Conversation className="px-3 [&>div]:scrollbar-none">
        <ConversationContent className="gap-4 py-3 h-fit">
          {messages.map(m => <ChatMessage key={m.id} message={m} />)}
        </ConversationContent>
        <ConversationScrollButton />
        <ConversationAutoScroller trigger={messages.length} />
      </Conversation>
      <ChatInput onSend={handleSend} />
    </div>
  );

  if (inline) return chatContent; // for /embed iframe

  return (
    <>
      <ChatButton isOpen={isOpen} onClick={() => setIsOpen(p => !p)} />
      <ChatContainer isOpen={isOpen} onClose={() => setIsOpen(false)}>
        {chatContent}
      </ChatContainer>
    </>
  );
}
```

## Embed via widget.js

Standalone JS file served from `/public/widget.js`. Creates FAB + iframe panel.

```html
<!-- Add to any host site -->
<script src="https://your-chatbot.example.com/widget.js"></script>
```

Configure Next.js headers for iframe embedding:

```ts
// next.config.ts
async headers() {
  return [
    {
      source: "/embed",
      headers: [
        { key: "X-Frame-Options", value: "ALLOWALL" },
        { key: "Content-Security-Policy", value: "frame-ancestors *" },
      ],
    },
  ];
}
```

Feature flag in host app:

```tsx
// Host app layout.tsx
{process.env.NEXT_PUBLIC_CHAT_URL && (
  <Script src={`${process.env.NEXT_PUBLIC_CHAT_URL}/widget.js`} strategy="lazyOnload" />
)}
```

## Lottie Callout

First-visit "How can I help?" bubble with animated arrow pointing to the FAB. Uses `lottie-react` and a Lottie JSON animation. Dismisses on chat open or X click. State persisted in localStorage.

## Scroll fix (critical)

The Conversation component from ai-elements uses `use-stick-to-bottom`. The key CSS rules:

- Parent: `flex h-full min-h-0 flex-col`
- Conversation: `relative flex-1 min-h-0` (the `min-h-0` is critical for flex overflow)
- ConversationContent: `h-fit` when messages exist, `h-full justify-center` when empty

Without `min-h-0`, the flex child grows unbounded and creates infinite scroll.
