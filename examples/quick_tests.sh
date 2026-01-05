#!/bin/bash
# Quick one-liner tests for llama-swappo-halo
# Run individual tests or use ./quick_tests.sh all

BASE_URL="http://localhost:8080/v1"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

test_python() {
    echo -e "${BLUE}Test: Python Function${NC}"
    curl -s "$BASE_URL/completions" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "deepseek-coder-v2-lite-instruct-q4_k_m",
            "prompt": "def calculate_average(numbers):\n    ",
            "max_tokens": 80
        }' | jq -r '.choices[0].text'
    echo ""
}

test_sql() {
    echo -e "${BLUE}Test: SQL Query${NC}"
    curl -s "$BASE_URL/completions" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "qwen2.5-coder-7b-instruct-q5_k_m",
            "prompt": "SELECT u.name, COUNT(o.id) as order_count FROM users u ",
            "max_tokens": 100
        }' | jq -r '.choices[0].text'
    echo ""
}

test_javascript() {
    echo -e "${BLUE}Test: JavaScript/TypeScript${NC}"
    curl -s "$BASE_URL/completions" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "deepseek-coder-v2-lite-instruct-q4_k_m",
            "prompt": "function fetchUserData(userId) {\n  ",
            "max_tokens": 100
        }' | jq -r '.choices[0].text'
    echo ""
}

test_explain() {
    echo -e "${BLUE}Test: Code Explanation${NC}"
    curl -s "$BASE_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "qwen2.5-coder-7b-instruct-q5_k_m",
            "messages": [
                {"role": "user", "content": "Explain this code:\n\ndef binary_search(arr, target):\n    left, right = 0, len(arr) - 1\n    while left <= right:\n        mid = (left + right) // 2\n        if arr[mid] == target:\n            return mid\n        elif arr[mid] < target:\n            left = mid + 1\n        else:\n            right = mid - 1\n    return -1"}
            ],
            "max_tokens": 150
        }' | jq -r '.choices[0].message.content'
    echo ""
}

test_rust() {
    echo -e "${BLUE}Test: Rust Code${NC}"
    curl -s "$BASE_URL/completions" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "qwen2.5-coder-7b-instruct-q5_k_m",
            "prompt": "struct User {\n    id: u32,\n    ",
            "max_tokens": 100
        }' | jq -r '.choices[0].text'
    echo ""
}

test_list_models() {
    echo -e "${BLUE}Test: List Available Models${NC}"
    curl -s "$BASE_URL/models" | jq -r '.data[] | "\(.id) - \(.name)"'
    echo ""
}

test_health() {
    echo -e "${BLUE}Test: Health Check${NC}"
    curl -s http://localhost:8080/health
    echo ""
}

# Run tests
case "${1:-all}" in
    python)
        test_python
        ;;
    sql)
        test_sql
        ;;
    js|javascript)
        test_javascript
        ;;
    explain)
        test_explain
        ;;
    rust)
        test_rust
        ;;
    models|list)
        test_list_models
        ;;
    health)
        test_health
        ;;
    all)
        echo -e "${GREEN}Running all tests...${NC}\n"
        test_health
        test_list_models
        test_python
        test_sql
        test_javascript
        test_explain
        test_rust
        ;;
    *)
        echo "Usage: $0 [test|all]"
        echo ""
        echo "Available tests:"
        echo "  all        - Run all tests (default)"
        echo "  python     - Python function generation"
        echo "  sql        - SQL query generation"
        echo "  js         - JavaScript function generation"
        echo "  explain    - Code explanation"
        echo "  rust       - Rust code generation"
        echo "  models     - List available models"
        echo "  health     - Health check"
        exit 1
        ;;
esac
