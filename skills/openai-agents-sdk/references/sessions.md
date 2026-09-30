# Sessions and history ownership

Choose one history owner per conversation:

| Owner | Next turn passes | Scope |
| --- | --- | --- |
| App: `result.to_input_list()` | that list plus the new user message | Any provider |
| SDK session | the same `session=` | Client-side store |
| `conversation_id` | the same ID plus only the new turn | OpenAI Responses |
| `previous_response_id` | `result.last_response_id` plus only the new turn | OpenAI Responses |

`session=` with `conversation_id`/`previous_response_id`/`auto_previous_response_id`
raises `UserError`. Mixing app-managed and server history duplicates context.

| Store | Import | Extra |
| --- | --- | --- |
| `SQLiteSession(id, db_path=...)` | `agents` | none; in-memory without `db_path` |
| `SQLAlchemySession.from_url(id, url="postgresql+asyncpg://...", create_tables=True)` | `agents.extensions.memory` | `sqlalchemy` |
| `RedisSession.from_url(id, url=...)` | `agents.extensions.memory` | `redis` |
| `AsyncSQLiteSession`, `AdvancedSQLiteSession`, `MongoDBSession`, `DaprSession` | `agents.extensions.memory` | per backend |
| `EncryptedSession(session_id=, underlying_session=, encryption_key=, ttl=)` | `agents.extensions.memory` | `encrypt` |
| `OpenAIConversationsSession(conversation_id=...)` | `agents` | none |
| `OpenAIResponsesCompactionSession(session_id=, underlying_session=)` | `agents` | none |

- 0.22.3 with SQLAlchemy 2.1: the `sqlalchemy` extra omits `greenlet`, so
  importing `SQLAlchemySession` fails. Add `sqlalchemy[asyncio]`.
- `EncryptedSession` defaults to `ttl=600`: items older than ten minutes are
  silently skipped. It encrypts at rest only, not provider requests or traces.
- A session ID selects history; it does not authenticate. Check ownership
  server-side and scope IDs per tenant. `SQLiteSession` does not detect edited or
  replayed rows.
- Auto-compaction keeps a streamed run open until it finishes. For low latency
  pass `should_trigger_compaction=lambda _: False` and call `run_compaction()`
  between turns.
- Persist replay-valid items, including tool call/result pairs and reasoning.

Define deletion and retention across app history, hosted conversation state,
logs and backups when in scope. Official docs:
[sessions](https://openai.github.io/openai-agents-python/sessions/),
[running agents](https://openai.github.io/openai-agents-python/running_agents/).
