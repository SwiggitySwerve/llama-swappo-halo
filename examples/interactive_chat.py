#!/usr/bin/env python3
"""
Interactive chat interface for llama-swappo-halo
Chat with the coding models in real-time
"""

import sys
from openai import OpenAI

class CodeChat:
    def __init__(self, model="deepseek-coder-v2-lite-instruct-q4_k_m"):
        self.client = OpenAI(base_url="http://localhost:8080/v1", api_key="dummy")
        self.model = model
        self.conversation = []

        models = {
            "deepseek": "deepseek-coder-v2-lite-instruct-q4_k_m",
            "qwen": "qwen2.5-coder-7b-instruct-q5_k_m"
        }

        if model in models:
            self.model = models[model]

        print(f"\n🤖 Code Chat - Model: {self.model}")
        print("="*60)
        print("Commands:")
        print("  /model <deepseek|qwen> - Switch model")
        print("  /clear - Clear conversation history")
        print("  /quit or Ctrl+D - Exit")
        print("="*60 + "\n")

    def send_message(self, user_input):
        """Send message and get response."""
        self.conversation.append({
            "role": "user",
            "content": user_input
        })

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=self.conversation,
                max_tokens=500,
                stream=True
            )

            print("\n🤖 Assistant:", end=" ", flush=True)
            assistant_message = ""

            for chunk in response:
                if chunk.choices[0].delta.content:
                    content = chunk.choices[0].delta.content
                    print(content, end="", flush=True)
                    assistant_message += content

            print("\n")

            self.conversation.append({
                "role": "assistant",
                "content": assistant_message
            })

        except Exception as e:
            print(f"\n❌ Error: {e}\n")

    def run(self):
        """Run interactive chat loop."""
        while True:
            try:
                user_input = input("👤 You: ").strip()

                if not user_input:
                    continue

                # Handle commands
                if user_input.lower() in ["/quit", "/exit", "/q"]:
                    print("\n👋 Goodbye!\n")
                    break

                elif user_input == "/clear":
                    self.conversation = []
                    print("\n✂️ Conversation cleared\n")
                    continue

                elif user_input.startswith("/model "):
                    new_model = user_input.split()[1].lower()
                    models = {
                        "deepseek": "deepseek-coder-v2-lite-instruct-q4_k_m",
                        "qwen": "qwen2.5-coder-7b-instruct-q5_k_m"
                    }
                    if new_model in models:
                        self.model = models[new_model]
                        self.conversation = []  # Clear on model switch
                        print(f"\n✅ Switched to {new_model}\n")
                    else:
                        print(f"\n❌ Unknown model. Use: deepseek or qwen\n")
                    continue

                # Regular message
                self.send_message(user_input)

            except EOFError:
                print("\n\n👋 Goodbye!\n")
                break
            except KeyboardInterrupt:
                print("\n\nUse /quit to exit\n")

def main():
    if len(sys.argv) > 1:
        model = sys.argv[1]
    else:
        model = "deepseek"  # Default to faster model

    chat = CodeChat(model=model)
    chat.run()

if __name__ == "__main__":
    main()
