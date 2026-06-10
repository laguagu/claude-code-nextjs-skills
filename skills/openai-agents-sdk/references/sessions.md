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
from agents import Agent, Runner, SQLiteSession

agent = Agent(name="ChatBot", instructions="Remember our conversation.")

# Session stores and loads history automatically
session = SQLiteSession("conversation_123")

result1 = await Runner.run(agent, "My name is John", session=session)
result2 = await Runner.run(agent, "What's my name?", session=session)
# -> "Your name is John"
```

## Advanced SQLite Session

```python
from agents import Agent, Runner, SQLiteSession

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
from agents.extensions.memory import RedisSession

session = RedisSession.from_url(
    "user_789",
    url="redis://localhost:6379",
    ttl=3600,  # 1 hour expiry
)
# Or pass an existing client: RedisSession("user_789", redis_client=client)

agent = Agent(name="ScalableBot", instructions="Be helpful.")

result = await Runner.run(agent, "Hello!", session=session)
```

## OpenAI Conversations Session

Using OpenAI's hosted Conversations API as storage:

```python
from agents import Agent, Runner, OpenAIConversationsSession

# Omit conversation_id to start a new conversation,
# or resume an existing one (keyword-only argument)
session = OpenAIConversationsSession(conversation_id="conv_123")

agent = Agent(
    name="OpenAIMemoryBot",
    instructions="Use your memory to help users.",
)

result = await Runner.run(agent, "Remember I like Python", session=session)
```

## Compaction Session

Automatically compact long conversations using the Responses API:

```python
from agents import Agent, Runner, OpenAIResponsesCompactionSession, SQLiteSession

base_session = SQLiteSession("long_conversation")

# Wraps another session and compacts history server-side when needed
session = OpenAIResponsesCompactionSession(
    session_id="long_conversation",
    underlying_session=base_session,
)
# Optional keyword-only params: client=, model="gpt-4.1",
# compaction_mode="auto", should_trigger_compaction=callable

agent = Agent(name="LongChatBot", instructions="Have long conversations.")

# After many messages, older ones are compacted automatically
for i in range(30):
    await Runner.run(agent, f"Message {i}", session=session)
```

## Encrypted Session

For sensitive conversations:

```python
from agents import Agent, Runner, SQLiteSession
from agents.extensions.memory import EncryptedSession

base_session = SQLiteSession("sensitive_chat")

session = EncryptedSession(
    session_id="sensitive_chat",
    underlying_session=base_session,
    encryption_key="your-32-byte-encryption-key-here",
    ttl=600,  # Items older than this can no longer be decrypted
)

agent = Agent(name="SecureBot", instructions="Handle sensitive information.")

result = await Runner.run(agent, "My SSN is 123-45-6789", session=session)
# Data stored encrypted in SQLite
```

## Session Comparison

| Session Type | Import | Storage | Use Case |
|--------------|--------|---------|----------|
| Manual (to_input_list) | - | Memory | Simple, single-request |
| SQLiteSession | `agents` | Local file | Single-server apps |
| AsyncSQLiteSession | `agents.extensions.memory` | Local file | Async SQLite access |
| AdvancedSQLiteSession | `agents.extensions.memory` | Local file | Branching, usage analytics |
| SQLAlchemySession | `agents.extensions.memory` | Any SQL DB | Postgres/MySQL etc. |
| RedisSession | `agents.extensions.memory` | Redis | Distributed systems |
| EncryptedSession | `agents.extensions.memory` | Wrapper | Sensitive data |
| OpenAIConversationsSession | `agents` | OpenAI Conversations API | Hosted history |
| OpenAIResponsesCompactionSession | `agents` | Wrapper | Long conversations |
| MongoDBSession | `agents.extensions.memory` | MongoDB | Document store |
| DaprSession | `agents.extensions.memory` | Dapr state store | Dapr-based apps |
