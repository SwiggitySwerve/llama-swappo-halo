# Model Usage Guide

Complete guide on how to use and consume the code models hosted on llama-swappo-halo.

## Table of Contents

- [Overview](#overview)
- [Available Models](#available-models)
- [API Reference](#api-reference)
- [Usage Examples by Language](#usage-examples-by-language)
- [Common Use Cases](#common-use-cases)
- [Best Practices](#best-practices)
- [Advanced Techniques](#advanced-techniques)
- [Troubleshooting](#troubleshooting)

---

## Overview

The llama-swappo-halo service provides an **Ollama-compatible API** for running code-focused LLMs on your local Strix Halo system. The API supports both completion and chat completion endpoints.

**Base URL**: `http://localhost:8080/v1`

**Features**:
- Ollama API compatible (works with existing Ollama clients)
- OpenAI API format (works with OpenAI SDKs)
- Streaming responses supported
- Multiple models available with automatic swapping

---

## Available Models

### qwen2.5-coder-7b-instruct-q5_k_m

**Best for**: General-purpose code generation, larger projects, complex logic

```bash
Model ID: qwen2.5-coder-7b-instruct-q5_k_m
Size: 5.07GB
Performance: ~10 tokens/second
Context: 32K tokens
HumanEval: 88.4%

Strengths:
- Excellent at Python, JavaScript, TypeScript
- Good at multi-file projects
- Strong documentation generation
- Handles large context windows
```

**When to use**:
- Generating complete functions/modules
- Code refactoring
- Writing tests
- Documentation generation
- Complex algorithmic tasks

### deepseek-coder-v2-lite-instruct-q4_k_m

**Best for**: Quick code generation, simple tasks, rapid iteration

```bash
Model ID: deepseek-coder-v2-lite-instruct-q4_k_m
Size: 9.65GB
Performance: ~27 tokens/second
Context: 16K tokens
HumanEval: 89%

Strengths:
- Faster response times
- Good at snippets and small functions
- Efficient for simple tasks
- Higher HumanEval score
```

**When to use**:
- Quick code snippets
- Simple function generation
- Bug fixes
- Code explanations
- When speed matters more than context

---

## API Reference

### List Models

Get all available models:

```bash
GET /v1/models
```

**Response**:
```json
{
  "object": "list",
  "data": [
    {
      "id": "qwen2.5-coder-7b-instruct-q5_k_m",
      "name": "Qwen2.5-Coder 7B Instruct",
      "description": "Code-focused language model with 32K context"
    },
    {
      "id": "deepseek-coder-v2-lite-instruct-q4_k_m",
      "name": "DeepSeek-Coder V2 Lite Instruct",
      "description": "Lightweight code-focused model with 16K context"
    }
  ]
}
```

### Completions API

Generate text completions:

```bash
POST /v1/completions
Content-Type: application/json
```

**Request Body**:
```json
{
  "model": "qwen2.5-coder-7b-instruct-q5_k_m",
  "prompt": "def fibonacci(n):\n    ",
  "max_tokens": 100,
  "temperature": 0.7,
  "stop": ["\n\n", "###"]
}
```

**Parameters**:
- `model` (required): Model ID to use
- `prompt` (required): Text to complete
- `max_tokens` (optional): Maximum tokens to generate (default: 128)
- `temperature` (optional): 0.0-2.0, higher = more creative (default: 0.8)
- `stop` (optional): Array of stop sequences
- `stream` (optional): Enable streaming (default: false)

**Response**:
```json
{
  "id": "chatcmpl-123",
  "object": "text_completion",
  "created": 1677652288,
  "model": "qwen2.5-coder-7b-instruct-q5_k_m",
  "choices": [{
    "index": 0,
    "text": "if n <= 0:\n        return 0\n    elif n == 1:\n        return 1\n    else:\n        return fibonacci(n-1) + fibonacci(n-2)",
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 5,
    "completion_tokens": 20,
    "total_tokens": 25
  }
}
```

### Chat Completions API

Generate chat-style completions:

```bash
POST /v1/chat/completions
Content-Type: application/json
```

**Request Body**:
```json
{
  "model": "deepseek-coder-v2-lite-instruct-q4_k_m",
  "messages": [
    {"role": "system", "content": "You are a helpful coding assistant."},
    {"role": "user", "content": "Write a function to parse JSON in Python"}
  ],
  "max_tokens": 200,
  "temperature": 0.5
}
```

**Parameters**:
- `model` (required): Model ID to use
- `messages` (required): Array of message objects
- `max_tokens` (optional): Maximum tokens to generate
- `temperature` (optional): Sampling temperature
- `stream` (optional): Enable streaming

**Response**:
```json
{
  "id": "chatcmpl-456",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "deepseek-coder-v2-lite-instruct-q4_k_m",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Here's a Python function to parse JSON:\n\nimport json\n\ndef parse_json(json_string):\n    try:\n        return json.loads(json_string)\n    except json.JSONDecodeError as e:\n        print(f\"Error parsing JSON: {e}\")\n        return None"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 30,
    "completion_tokens": 50,
    "total_tokens": 80
  }
}
```

### Health Check

Check service status:

```bash
GET /health
```

**Response**: `200 OK` (with body "OK")

---

## Usage Examples by Language

### Python (Recommended)

#### Using OpenAI Client

```python
from openai import OpenAI

# Initialize client
client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="dummy"  # Not used but required
)

# Simple completion
response = client.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    prompt="def quick_sort(arr):\n    ",
    max_tokens=100
)
print(response.choices[0].text)

# Chat completion
response = client.chat.completions.create(
    model="deepseek-coder-v2-lite-instruct-q4_k_m",
    messages=[
        {"role": "system", "content": "You are an expert Python developer."},
        {"role": "user", "content": "Write a async function to fetch data from an API"}
    ],
    max_tokens=200
)
print(response.choices[0].message.content)
```

#### Using Requests (Raw HTTP)

```python
import requests
import json

API_URL = "http://localhost:8080/v1"

def generate_code(prompt, model="qwen2.5-coder-7b-instruct-q5_k_m"):
    response = requests.post(
        f"{API_URL}/completions",
        json={
            "model": model,
            "prompt": prompt,
            "max_tokens": 200
        }
    )
    return response.json()

def chat(messages, model="deepseek-coder-v2-lite-instruct-q4_k_m"):
    response = requests.post(
        f"{API_URL}/chat/completions",
        json={
            "model": model,
            "messages": messages,
            "max_tokens": 500
        }
    )
    return response.json()

# Usage
result = generate_code("SELECT * FROM users WHERE ")
print(result['choices'][0]['text'])

chat_result = chat([
    {"role": "user", "content": "Explain what this code does: def foo(x): return x**2"}
])
print(chat_result['choices'][0]['message']['content'])
```

#### Streaming Example

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="dummy"
)

stream = client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[
        {"role": "user", "content": "Write a React component for a todo list"}
    ],
    stream=True,
    max_tokens=300
)

for chunk in stream:
    if chunk.choices[0].delta.content is not None:
        print(chunk.choices[0].delta.content, end="")
```

### JavaScript/TypeScript

#### Using OpenAI SDK

```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'http://localhost:8080/v1',
  apiKey: 'dummy' // Not used but required
});

async function generateCode() {
  const completion = await client.chat.completions.create({
    model: 'qwen2.5-coder-7b-instruct-q5_k_m',
    messages: [
      { role: 'user', content: 'Write a Node.js function to read a file' }
    ],
    max_tokens: 200
  });

  console.log(completion.choices[0].message.content);
}

generateCode();
```

#### Using Fetch API

```javascript
const API_URL = 'http://localhost:8080/v1';

async function generateCode(prompt, model = 'deepseek-coder-v2-lite-instruct-q4_k_m') {
  const response = await fetch(`${API_URL}/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: model,
      prompt: prompt,
      max_tokens: 200
    })
  });

  const data = await response.json();
  return data.choices[0].text;
}

// Usage
generateCode('function binarySearch(arr, target) {')
  .then(code => console.log(code));
```

### Go

```go
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

const API_URL = "http://localhost:8080/v1"

type CompletionRequest struct {
	Model    string `json:"model"`
	Prompt   string `json:"prompt"`
	MaxTokens int   `json:"max_tokens"`
}

type CompletionResponse struct {
	Choices []struct {
		Text string `json:"text"`
	} `json:"choices"`
}

func generateCode(prompt string) (string, error) {
	reqBody := CompletionRequest{
		Model:     "qwen2.5-coder-7b-instruct-q5_k_m",
		Prompt:    prompt,
		MaxTokens: 200,
	}

	jsonData, _ := json.Marshal(reqBody)
	resp, err := http.Post(API_URL+"/completions", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result CompletionResponse
	json.Unmarshal(body, &result)

	return result.Choices[0].Text, nil
}

func main() {
	code, err := generateCode("func main() {\n")
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}
	fmt.Println(code)
}
```

### Rust

```rust
use reqwest::Client;
use serde::{Deserialize, Serialize};

const API_URL: &str = "http://localhost:8080/v1";

#[derive(Serialize)]
struct CompletionRequest {
    model: String,
    prompt: String,
    max_tokens: u32,
}

#[derive(Deserialize)]
struct CompletionResponse {
    choices: Vec<Choice>,
}

#[derive(Deserialize)]
struct Choice {
    text: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = Client::new();

    let request = CompletionRequest {
        model: "deepseek-coder-v2-lite-instruct-q4_k_m".to_string(),
        prompt: "fn main() {\n".to_string(),
        max_tokens: 100,
    };

    let response = client
        .post(format!("{}/completions", API_URL))
        .json(&request)
        .send()
        .await?;

    let result: CompletionResponse = response.json().await?;
    println!("{}", result.choices[0].text);

    Ok(())
}
```

### cURL

```bash
# Simple completion
curl http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q5_k_m",
    "prompt": "def factorial(n):\n    ",
    "max_tokens": 50
  }'

# Chat completion
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-coder-v2-lite-instruct-q4_k_m",
    "messages": [
      {"role": "user", "content": "Write a bash script to backup a directory"}
    ],
    "max_tokens": 200
  }' | jq -r '.choices[0].message.content'

# List models
curl http://localhost:8080/v1/models | jq '.data[] | {id, name}'
```

---

## Common Use Cases

### 1. Code Generation

Generate complete functions from descriptions:

```python
client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[
        {
            "role": "user",
            "content": "Write a Python function that validates email addresses using regex"
        }
    ],
    max_tokens=150
)
```

### 2. Code Explanation

Get explanations for code:

```python
code = """
def merge_sort(arr):
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    return merge(left, right)
"""

client.chat.completions.create(
    model="deepseek-coder-v2-lite-instruct-q4_k_m",
    messages=[
        {
            "role": "user",
            "content": f"Explain what this code does:\n\n{code}"
        }
    ],
    max_tokens=300
)
```

### 3. Code Refactoring

Ask for improvements to existing code:

```python
client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[
        {
            "role": "user",
            "content": """Refactor this code to be more Pythonic and efficient:

def get_unique_items(data):
    result = []
    for item in data:
        if item not in result:
            result.append(item)
    return result"""
        }
    ],
    max_tokens=200
)
```

### 4. Test Generation

Generate unit tests:

```python
client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[
        {
            "role": "user",
            "content": """Write unit tests for this function using pytest:

def calculate_discount(price, percentage):
    return price * (1 - percentage / 100)"""
        }
    ],
    max_tokens=300
)
```

### 5. Debugging

Get help finding bugs:

```python
client.chat.completions.create(
    model="deepseek-coder-v2-lite-instruct-q4_k_m",
    messages=[
        {
            "role": "user",
            "content": """Find the bug in this code:

for i in range(len(arr)):
    if arr[i] == target:
        return i
# What's wrong with this code?"""
        }
    ],
    max_tokens=200
)
```

### 6. Documentation

Generate docstrings and comments:

```python
client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[
        {
            "role": "user",
            "content": """Add comprehensive docstrings to this function:

def process_data(data, filter_empty=True):
    result = {}
    for k, v in data.items():
        if filter_empty and not v:
            continue
        result[k] = v.strip() if isinstance(v, str) else v
    return result"""
        }
    ],
    max_tokens=250
)
```

### 7. Multi-Language Support

Generate code in different languages:

```python
# JavaScript
client.chat.completions.create(
    model="deepseek-coder-v2-lite-instruct-q4_k_m",
    messages=[{"role": "user", "content": "Write a JavaScript function to debounce a function call"}],
    max_tokens=150
)

# Rust
client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[{"role": "user", "content": "Write a Rust struct for a User with id, name, email fields"}],
    max_tokens=150
)

# SQL
client.chat.completions.create(
    model="deepseek-coder-v2-lite-instruct-q4_k_m",
    messages=[{"role": "user", "content": "Write a SQL query to find duplicate emails in users table"}],
    max_tokens=150
)
```

---

## Best Practices

### 1. Choose the Right Model

```
Quick tasks → deepseek-coder-v2-lite-instruct-q4_k_m (faster)
Complex tasks → qwen2.5-coder-7b-instruct-q5_k_m (more capable)
```

### 2. Write Clear Prompts

**Bad**:
```
"Write code"
```

**Good**:
```
"Write a Python function to validate email addresses using regex.
Return True if valid, False otherwise. Include error handling."
```

### 3. Provide Context

Include relevant code and requirements:

```python
client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[
        {
            "role": "user",
            "content": """I'm using FastAPI and SQLAlchemy. Write an endpoint to:
1. Create a new user
2. Validate email uniqueness
3. Hash password with bcrypt
4. Return user object without password

User model:
- id: Integer, primary key
- email: String, unique
- hashed_password: String"""
        }
    ]
)
```

### 4. Use Temperature Effectively

```python
# Deterministic output (bug fixes, tests)
completion = client.completions.create(
    model="deepseek-coder-v2-lite-instruct-q4_k_m",
    prompt="def fibonacci(n):",
    temperature=0.1,  # Lower = more deterministic
    max_tokens=100
)

# Creative output (naming, suggestions)
completion = client.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    prompt="Suggest names for a variable holding user authentication token:",
    temperature=0.8,  # Higher = more creative
    max_tokens=50
)
```

### 5. Set Appropriate Token Limits

```python
# Short responses
max_tokens=50   # Function signatures, variable names

# Medium responses
max_tokens=150  # Single functions, bug fixes

# Long responses
max_tokens=500  # Complete modules, documentation
```

### 6. Use Streaming for Long Responses

```python
for chunk in client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[{"role": "user", "content": "Write a complete REST API"}],
    stream=True,
    max_tokens=1000
):
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

### 7. Implement Error Handling

```python
from openai import OpenAI
from openai import APIError, APITimeoutError

client = OpenAI(base_url="http://localhost:8080/v1", api_key="dummy")

try:
    response = client.chat.completions.create(
        model="qwen2.5-coder-7b-instruct-q5_k_m",
        messages=[{"role": "user", "content": "Write code"}],
        timeout=30  # 30 second timeout
    )
except APITimeoutError:
    print("Request timed out. Try again or reduce max_tokens.")
except APIError as e:
    print(f"API error: {e}")
```

### 8. Cache Common Responses

```python
import hashlib
import json

def cache_key(prompt, model):
    return hashlib.md5(f"{model}:{prompt}".encode()).hexdigest()

# Simple in-memory cache
response_cache = {}

def get_cached_completion(prompt, model="qwen2.5-coder-7b-instruct-q5_k_m"):
    key = cache_key(prompt, model)
    if key in response_cache:
        return response_cache[key]

    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=200
    )

    response_cache[key] = response
    return response
```

---

## Advanced Techniques

### Conversation History

Maintain context across multiple requests:

```python
conversation = [
    {"role": "system", "content": "You are a helpful coding assistant."}
]

def ask(question):
    conversation.append({"role": "user", "content": question})
    response = client.chat.completions.create(
        model="qwen2.5-coder-7b-instruct-q5_k_m",
        messages=conversation,
        max_tokens=200
    )
    assistant_message = response.choices[0].message.content
    conversation.append({"role": "assistant", "content": assistant_message})
    return assistant_message

# Multi-turn conversation
ask("Write a function to parse CSV files")
ask("Now add error handling for malformed rows")
ask("Add support for custom delimiters")
```

### Function Calling Pattern

Use the model to decide which function to call:

```python
def get_user_response(user_query):
    response = client.chat.completions.create(
        model="qwen2.5-coder-7b-instruct-q5_k_m",
        messages=[{
            "role": "user",
            "content": f"""Classify this request into one of:
- CODE_GENERATION
- CODE_EXPLANATION
- DEBUGGING

Request: {user_query}

Respond with only the category name."""
        }],
        max_tokens=10,
        temperature=0
    )

    category = response.choices[0].message.content.strip()

    if category == "CODE_GENERATION":
        return generate_code(user_query)
    elif category == "CODE_EXPLANATION":
        return explain_code(user_query)
    elif category == "DEBUGGING":
        return debug_code(user_query)
```

### Batch Processing

Process multiple requests efficiently:

```python
import asyncio
from openai import AsyncOpenAI

client = AsyncOpenAI(base_url="http://localhost:8080/v1", api_key="dummy")

async def generate_code_async(prompt):
    response = await client.chat.completions.create(
        model="deepseek-coder-v2-lite-instruct-q4_k_m",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=150
    )
    return response.choices[0].message.content

async def batch_generate(prompts):
    tasks = [generate_code_async(p) for p in prompts]
    return await asyncio.gather(*tasks)

# Usage
prompts = [
    "Write a function to sort an array",
    "Write a function to search an array",
    "Write a function to filter an array"
]

results = asyncio.run(batch_generate(prompts))
```

### Structured Output

Parse structured data from responses:

```python
import json
import re

def extract_code_blocks(response_text):
    """Extract code blocks from markdown-formatted response."""
    pattern = r'```(\w+)?\n(.*?)```'
    matches = re.findall(pattern, response_text, re.DOTALL)
    return [{'language': lang or 'text', 'code': code} for lang, code in matches]

response = client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[{"role": "user", "content": "Write functions for stack operations"}],
    max_tokens=500
)

code_blocks = extract_code_blocks(response.choices[0].message.content)
for block in code_blocks:
    print(f"Language: {block['language']}")
    print(f"Code:\n{block['code']}\n")
```

---

## Troubleshooting

### Issue: Slow Response Times

**Symptoms**: Requests take 30+ seconds

**Solutions**:
1. Use `deepseek-coder-v2-lite-instruct-q4_k_m` instead of `qwen2.5-coder-7b-instruct-q5_k_m`
2. Reduce `max_tokens` parameter
3. Break complex requests into smaller chunks
4. Use CPU-only mode (already configured)

### Issue: Poor Code Quality

**Symptoms**: Generated code has errors or doesn't match requirements

**Solutions**:
1. Be more specific in your prompt
2. Provide example input/output
3. Include constraints and requirements in the prompt
4. Use lower `temperature` (0.1-0.3) for more deterministic output
5. Try the other model (Qwen vs DeepSeek)

### Issue: Cut-off Responses

**Symptoms**: Response ends mid-sentence or incomplete

**Solutions**:
1. Increase `max_tokens`
2. Use streaming API to handle partial responses
3. Break request into smaller parts

### Issue: Connection Refused

**Symptoms**: Cannot connect to `localhost:8080`

**Solutions**:
```bash
# Check if service is running
kubectl get pods -l app=llama-swappo-halo

# Check service endpoint
kubectl get svc llama-swappo-halo

# View logs
kubectl logs -l app=llama-swappo-halo

# Restart if needed
kubectl rollout restart deployment/llama-swappo-halo
```

### Issue: Model Not Found

**Symptoms**: `"model_not_found"` error

**Solutions**:
1. List available models: `curl http://localhost:8080/v1/models`
2. Check model ID spelling
3. Verify config has the model configured
4. Check pod logs for model loading errors

---

## Reference Implementations

### Complete CLI Tool

```python
#!/usr/bin/env python3
"""
Command-line tool for interacting with llama-swappo-halo
"""

import argparse
import sys
from openai import OpenAI

def main():
    parser = argparse.ArgumentParser(description="LLM Code Generation CLI")
    parser.add_argument("prompt", help="Code generation prompt")
    parser.add_argument("-m", "--model",
                       choices=["qwen", "deepseek"],
                       default="deepseek",
                       help="Model to use (default: deepseek)")
    parser.add_argument("-t", "--max-tokens", type=int, default=200,
                       help="Maximum tokens to generate")
    parser.add_argument("--temp", type=float, default=0.7,
                       help="Temperature (0.0-2.0)")
    parser.add_argument("-s", "--stream", action="store_true",
                       help="Enable streaming")

    args = parser.parse_args()

    model_map = {
        "qwen": "qwen2.5-coder-7b-instruct-q5_k_m",
        "deepseek": "deepseek-coder-v2-lite-instruct-q4_k_m"
    }

    client = OpenAI(
        base_url="http://localhost:8080/v1",
        api_key="dummy"
    )

    try:
        if args.stream:
            stream = client.chat.completions.create(
                model=model_map[args.model],
                messages=[{"role": "user", "content": args.prompt}],
                max_tokens=args.max_tokens,
                temperature=args.temp,
                stream=True
            )
            for chunk in stream:
                if chunk.choices[0].delta.content:
                    print(chunk.choices[0].delta.content, end="", flush=True)
            print()
        else:
            response = client.chat.completions.create(
                model=model_map[args.model],
                messages=[{"role": "user", "content": args.prompt}],
                max_tokens=args.max_tokens,
                temperature=args.temp
            )
            print(response.choices[0].message.content)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
```

Usage:
```bash
# Simple usage
python codegen.py "Write a function to validate email addresses"

# Use Qwen model
python codegen.py "Write a binary search function" -m qwen

# Streaming output
python codegen.py "Write a React component" -s

# Low temperature for deterministic output
python codegen.py "Fix this bug: ..." --temp 0.1
```

---

## Additional Resources

- [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [llama-swappo GitHub](https://github.com/Mootikins/llama-swappo)
