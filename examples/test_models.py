#!/usr/bin/env python3
"""
Quick test script for llama-swappo-halo models
Tests both models with various code generation tasks
"""

import time
from openai import OpenAI

# Initialize client
client = OpenAI(base_url="http://localhost:8080/v1", api_key="dummy")

def test_model(model_id, model_name, prompt, max_tokens=100):
    """Test a model and measure performance."""
    print(f"\n{'='*60}")
    print(f"Testing: {model_name}")
    print(f"{'='*60}")
    print(f"Prompt: {prompt[:50]}...")
    print(f"\nGenerating...")

    start = time.time()
    response = client.chat.completions.create(
        model=model_id,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=max_tokens
    )
    elapsed = time.time() - start

    result = response.choices[0].message.content
    usage = response.usage

    print(f"\nResult:\n{'-'*60}")
    print(result)
    print(f"\n{'-'*60}")
    print(f"Tokens: {usage.completion_tokens} generated, {usage.prompt_tokens} prompt")
    print(f"Time: {elapsed:.2f} seconds")
    print(f"Speed: {usage.completion_tokens/elapsed:.1f} tokens/second")

    return result, elapsed

def main():
    print("\n" + "="*60)
    print("llama-swappo-halo Model Test Suite")
    print("="*60)

    # Test cases
    tests = [
        {
            "name": "Simple Python Function",
            "prompt": "Write a Python function to calculate the factorial of a number.",
            "max_tokens": 80
        },
        {
            "name": "SQL Query",
            "prompt": "Write a SQL query to find all users who registered in the last 7 days.",
            "max_tokens": 60
        },
        {
            "name": "JavaScript/TypeScript",
            "prompt": "Write a JavaScript function to debounce a function call.",
            "max_tokens": 100
        },
        {
            "name": "Code Explanation",
            "prompt": """Explain what this code does:
def merge_sort(arr):
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    return merge(left, right)""",
            "max_tokens": 150
        },
        {
            "name": "Bug Fix",
            "prompt": """Find and fix the bug in this code:
for i in range(len(arr)):
    if arr[i] == target:
        return i
# Bug: returns -1 even if element exists""",
            "max_tokens": 120
        }
    ]

    models = [
        {
            "id": "deepseek-coder-v2-lite-instruct-q4_k_m",
            "name": "DeepSeek-Coder V2 Lite (Fast)"
        },
        {
            "id": "qwen2.5-coder-7b-instruct-q5_k_m",
            "name": "Qwen2.5-Coder 7B (Capable)"
        }
    ]

    # Run tests
    results = {}
    for model in models:
        model_id = model["id"]
        model_name = model["name"]
        results[model_id] = []

        print(f"\n\n{'#'*60}")
        print(f"# {model_name}")
        print(f"#'*60}")

        for test in tests:
            try:
                result, elapsed = test_model(
                    model_id,
                    model_name,
                    test["prompt"],
                    test["max_tokens"]
                )
                results[model_id].append({
                    "test": test["name"],
                    "time": elapsed,
                    "success": True
                })
                time.sleep(1)  # Brief pause between tests
            except Exception as e:
                print(f"\n❌ Error: {e}")
                results[model_id].append({
                    "test": test["name"],
                    "time": 0,
                    "success": False,
                    "error": str(e)
                })

    # Summary
    print(f"\n\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")

    for model in models:
        model_id = model["id"]
        model_results = results[model_id]
        successful = sum(1 for r in model_results if r["success"])
        total = len(model_results)
        avg_time = sum(r["time"] for r in model_results if r["success"]) / max(successful, 1)

        print(f"\n{model['name']}")
        print(f"  Tests passed: {successful}/{total}")
        print(f"  Average time: {avg_time:.2f}s")

    print(f"\n{'='*60}\n")

if __name__ == "__main__":
    main()
