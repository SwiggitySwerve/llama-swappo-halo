# Web UI for Llama Swappo

This directory contains web-based interfaces for interacting with llama-swappo-halo.

## Option 1: Built-in Dashboard (Lightweight)

Simple HTML/JavaScript dashboard for basic model management and chat.

### Quick Start

```bash
# Start the dashboard server
cd webui
python3 server.py

# Or specify a different port
python3 server.py 8082

# Access at http://localhost:8081
```

### Features

- ✅ Model selection and switching
- ✅ Interactive chat interface
- ✅ Code syntax highlighting
- ✅ Real-time health monitoring
- ✅ Usage statistics tracking
- ✅ No dependencies required (pure HTML/JS)

### Screenshots

The dashboard includes:
- **Model Panel**: View and select available models
- **Chat Interface**: Interactive chat with code formatting
- **Statistics Panel**: Track requests, tokens, and response times
- **Health Indicator**: Real-time service status

### Browser Compatibility

Works in any modern browser:
- Chrome/Edge 90+
- Firefox 88+
- Safari 14+

---

## Option 2: Open WebUI (Full Featured)

Open WebUI is a powerful, feature-rich UI compatible with Ollama APIs.

### Installation

```bash
# Using Docker
docker run -d \
  --name open-webui \
  -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main

# Or using pip
pip install open-webui
open-webui serve --port 3000
```

### Configuration

1. Open http://localhost:3000
2. Go to Settings → Providers
3. Add Custom Endpoint:
   - Name: `Llama Swappo`
   - URL: `http://host.docker.internal:8080/v1` (Docker)
   - URL: `http://localhost:8080/v1` (Local)

### Features

✅ **Everything in Built-in Dashboard, plus:**
- Multiple chat conversations
- Prompt library and templates
- File upload and RAG
- Model parameters adjustment (temperature, top_p, etc.)
- Code execution playground
- User management and authentication
- API key management
- Export/import chats
- Dark mode
- Mobile responsive

### Use Cases

- **Daily coding tasks**: Built-in dashboard
- **Complex projects**: Open WebUI (with RAG and file support)
- **Team collaboration**: Open WebUI (with user management)
- **Quick testing**: Built-in dashboard (no setup required)

---

## Option 3: Continue.dev (VS Code Extension)

AI coding assistant that connects to llama-swappo.

### Installation

1. Install VS Code
2. Install Continue extension
3. Configure in VS Code settings:

```json
{
  "continue.ollamaBaseURL": "http://localhost:8080"
}
```

### Features

- Code completion inline
- Chat sidebar for code questions
- Edit code with AI suggestions
- Context-aware responses
- Multiple file editing

---

## Option 4: Custom Integration

Build your own UI using the API:

### Python Example

```python
from flask import Flask, render_template, request, jsonify
from openai import OpenAI
import os

app = Flask(__name__)
client = OpenAI(base_url="http://localhost:8080/v1", api_key="dummy")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/chat', methods=['POST'])
def chat():
    data = request.json
    response = client.chat.completions.create(
        model=data['model'],
        messages=data['messages'],
        max_tokens=1000
    )
    return jsonify(response.dict())

if __name__ == '__main__':
    app.run(port=3000)
```

---

## Comparison

| Feature | Built-in | Open WebUI | Continue.dev |
|---------|----------|------------|--------------|
| Setup Time | 0 min | 2 min | 1 min |
| Chat Interface | ✅ | ✅ | ✅ |
| Model Management | ✅ | ✅ | ✅ |
| Code Highlighting | ✅ | ✅ | ✅ (inline) |
| File Upload | ❌ | ✅ | ✅ |
| RAG Support | ❌ | ✅ | ✅ |
| Prompt Library | ❌ | ✅ | ❌ |
| VS Code Integration | ❌ | ❌ | ✅ |
| Dependencies | None | Docker/Pip | VS Code |
| Resource Usage | Very Low | Medium | Low |

---

## Troubleshooting

### Dashboard Shows "Offline"

**Problem**: Cannot connect to llama-swappo API

**Solutions**:
```bash
# Check if service is running
kubectl get pods -l app=llama-swappo-halo

# Check API directly
curl http://localhost:8080/health

# Restart dashboard
python3 server.py
```

### CORS Errors

**Problem**: Browser blocks requests to API

**Solution**: The built-in server handles CORS automatically. If using your own server, add these headers:

```python
headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
}
```

### Models Not Loading

**Problem**: Dashboard can't fetch model list

**Solutions**:
```bash
# Check API manually
curl http://localhost:8080/v1/models

# Check pod logs
kubectl logs -l app=llama-swappo-halo

# Verify config
kubectl exec -it <pod-name> -- cat /app/config.yaml
```

---

## Development

### Modifying the Built-in Dashboard

The dashboard is pure HTML/JS/Python:

```bash
# Edit dashboard.html
vim webui/dashboard.html

# Test changes
python3 webui/server.py

# Browser will auto-refresh on file changes
```

### Adding New Features

1. Edit `dashboard.html` to add UI elements
2. Add JavaScript functions in the `<script>` section
3. Test by refreshing the browser

Example: Add model parameter controls

```javascript
// Add to dashboard.html
function updateParameters() {
    const temperature = document.getElementById('temperature').value;
    const maxTokens = document.getElementById('maxTokens').value;
    // Use in API call
}
```

---

## Security Note

⚠️ **The built-in dashboard binds to 0.0.0.0 and is accessible from your network.**

For production use:
1. Use a reverse proxy (nginx) with authentication
2. Or use Open WebUI which has built-in user management
3. Or run locally only: Change server.py to bind to `127.0.0.1`

---

## Quick Reference

### Start Dashboard

```bash
cd /path/to/llama-swappo-halo
python3 webui/server.py
# Open http://localhost:8081
```

### Start Open WebUI

```bash
docker run -d \
  -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
# Open http://localhost:3000
# Configure endpoint: http://host.docker.internal:8080/v1
```

### Start Continue.dev

```bash
# Install in VS Code
# Install Continue extension
# Configure: Settings → Continue → Ollama Base URL → http://localhost:8080
```
