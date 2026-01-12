# Streaming

## Basic Streaming

```python
from openai.types.responses import ResponseTextDeltaEvent
from agents import Agent, Runner

agent = Agent(name="Writer", instructions="Write stories.")

result = Runner.run_streamed(agent, input="Write a short story")

async for event in result.stream_events():
    if event.type == "raw_response_event":
        if isinstance(event.data, ResponseTextDeltaEvent):
            print(event.data.delta, end="", flush=True)
```

## Stream Items

```python
from agents import Agent, Runner

agent = Agent(name="Assistant", instructions="Be helpful.")

result = Runner.run_streamed(agent, input="Tell me about Python")

async for item in result.stream_items():
    print(f"Item type: {item.type}")
    if hasattr(item, "text"):
        print(f"Text: {item.text}")
```

## SSE Streaming with FastAPI

```python
import json
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from openai.types.responses import ResponseTextDeltaEvent
from agents import Agent, Runner

app = FastAPI()

agent = Agent(name="Assistant", instructions="Be helpful.")

def sse(event: str, data: dict) -> str:
    return f"event: {event}\ndata: {json.dumps(data)}\n\n"

@app.post("/stream")
async def stream_response(prompt: str):
    async def generate():
        result = Runner.run_streamed(agent, input=prompt)

        async for event in result.stream_events():
            if event.type == "raw_response_event":
                if isinstance(event.data, ResponseTextDeltaEvent):
                    yield sse("delta", {"text": event.data.delta})

        yield sse("done", {})

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
    )
```

## Streaming with Tool Calls

```python
from agents import Agent, Runner, function_tool
from openai.types.responses import ResponseTextDeltaEvent, ResponseFunctionCallArgumentsDeltaEvent

@function_tool
def get_data(query: str) -> str:
    return f"Data for {query}"

agent = Agent(
    name="DataBot",
    instructions="Fetch data when asked.",
    tools=[get_data],
)

result = Runner.run_streamed(agent, input="Get data about sales")

async for event in result.stream_events():
    if event.type == "raw_response_event":
        if isinstance(event.data, ResponseTextDeltaEvent):
            print(f"Text: {event.data.delta}", end="")
        elif isinstance(event.data, ResponseFunctionCallArgumentsDeltaEvent):
            print(f"Tool args: {event.data.delta}", end="")
```

## Streaming with Guardrails

```python
from agents import Agent, Runner, input_guardrail
from agents import GuardrailFunctionOutput, RunContextWrapper

@input_guardrail
async def check_input(
    ctx: RunContextWrapper, agent: Agent, input: str
) -> GuardrailFunctionOutput:
    if "bad" in input.lower():
        return GuardrailFunctionOutput(
            tripwire_triggered=True,
            output_info="Inappropriate content",
        )
    return GuardrailFunctionOutput(tripwire_triggered=False)

agent = Agent(
    name="SafeBot",
    instructions="Be helpful.",
    input_guardrails=[check_input],
)

try:
    result = Runner.run_streamed(agent, input="Hello")
    async for event in result.stream_events():
        # Process events
        pass
except Exception as e:
    print(f"Guardrail triggered: {e}")
```

## Collecting Full Response

```python
result = Runner.run_streamed(agent, input="Tell me a story")

# Stream first
async for event in result.stream_events():
    if event.type == "raw_response_event":
        if isinstance(event.data, ResponseTextDeltaEvent):
            print(event.data.delta, end="")

# Then get full result
final_result = await result.final_result()
print(f"\n\nFull output: {final_result.final_output}")
```
