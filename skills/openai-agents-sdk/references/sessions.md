# Sessions

## Conversation History with to_input_list()

Manual conversation history management:

```python
from agents import Agent, Runner, TResponseInputItem

agent = Agent(name="ChatBot", instructions="Be helpful.")

# First message
result = await Runner.run(agent, "Hello!")

# Continue conversation with history
inputs = result.to_input_list()
inputs.append({"role": "user", "content": "Tell me more"})

result = await Runner.run(agent, inputs)
```

## SQLite Session

Automatic conversation history with SQLite:

```python
from agents import Agent, Runner
from agents.extensions.sessions import SQLiteSession

agent = Agent(name="ChatBot", instructions="Remember our conversation.")

# Session stores and loads history automatically
session = SQLiteSession("conversation_123")

result1 = await Runner.run(agent, "My name is John", session=session)
result2 = await Runner.run(agent, "What's my name?", session=session)
# -> "Your name is John"
```

## Advanced SQLite Session

```python
from agents import Agent, Runner
from agents.extensions.sessions import SQLiteSession

# Custom database path
session = SQLiteSession(
    session_id="user_456_chat",
    db_path="./data/conversations.db",
)

agent = Agent(
    name="MemoryBot",
    instructions="Remember user preferences and history.",
)

# Multiple conversations with same agent
await Runner.run(agent, "I prefer dark mode", session=session)
await Runner.run(agent, "Set language to Finnish", session=session)

# Later session retrieval
session2 = SQLiteSession(session_id="user_456_chat", db_path="./data/conversations.db")
result = await Runner.run(agent, "What are my preferences?", session=session2)
# -> Remembers dark mode and Finnish language
```

## Redis Session

For distributed systems:

```python
from agents import Agent, Runner
from agents.extensions.sessions import RedisSession

session = RedisSession(
    session_id="user_789",
    redis_url="redis://localhost:6379",
    ttl=3600,  # 1 hour expiry
)

agent = Agent(name="ScalableBot", instructions="Be helpful.")

result = await Runner.run(agent, "Hello!", session=session)
```

## OpenAI Session

Using OpenAI's built-in memory:

```python
from agents import Agent, Runner
from agents.extensions.sessions import OpenAISession

session = OpenAISession(session_id="openai_session_123")

agent = Agent(
    name="OpenAIMemoryBot",
    instructions="Use your memory to help users.",
)

result = await Runner.run(agent, "Remember I like Python", session=session)
```

## Compaction Session

Automatically summarize long conversations:

```python
from agents import Agent, Runner
from agents.extensions.sessions import CompactionSession, SQLiteSession

base_session = SQLiteSession("long_conversation")

# Compacts history when it exceeds threshold
session = CompactionSession(
    base_session=base_session,
    max_messages=20,  # Compact after 20 messages
    summary_model="gpt-5.2-mini",  # Model for summarization
)

agent = Agent(name="LongChatBot", instructions="Have long conversations.")

# After many messages, older ones are summarized
for i in range(30):
    await Runner.run(agent, f"Message {i}", session=session)
```

## Encrypted Session

For sensitive conversations:

```python
from agents import Agent, Runner
from agents.extensions.sessions import EncryptedSession, SQLiteSession

base_session = SQLiteSession("sensitive_chat")

session = EncryptedSession(
    base_session=base_session,
    encryption_key="your-32-byte-encryption-key-here",
)

agent = Agent(name="SecureBot", instructions="Handle sensitive information.")

result = await Runner.run(agent, "My SSN is 123-45-6789", session=session)
# Data stored encrypted in SQLite
```

## Session Comparison

| Session Type | Storage | Use Case |
|--------------|---------|----------|
| Manual (to_input_list) | Memory | Simple, single-request |
| SQLiteSession | Local file | Single-server apps |
| RedisSession | Redis | Distributed systems |
| OpenAISession | OpenAI | Using OpenAI memory |
| CompactionSession | Wrapper | Long conversations |
| EncryptedSession | Wrapper | Sensitive data |
