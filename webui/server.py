#!/usr/bin/env python3
"""
Simple web server for Llama Swappo Dashboard
Serves the HTML dashboard and handles CORS for the API
"""

from http.server import HTTPServer, SimpleHTTPRequestHandler
import os
import sys

class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

def run_server(port=8081):
    """Start the web server."""
    # Change to webui directory
    webui_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(webui_dir)

    server_address = ('', port)
    httpd = HTTPServer(server_address, CORSRequestHandler)

    print(f"""
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🦙 Llama Swappo Dashboard                              ║
║                                                           ║
║   Dashboard: http://localhost:{port}                     ║
║   API Proxy: Enabled (CORS)                               ║
║                                                           ║
║   Press Ctrl+C to stop                                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    """)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Shutting down dashboard...")
        httpd.server_close()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8081
    run_server(port)
