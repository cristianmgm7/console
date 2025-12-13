#!/usr/bin/env python3
"""
Simple HTTP server that serves Flutter web app with SPA routing support.
All routes serve index.html to support client-side routing.
"""
import http.server
import socketserver
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
# Get directory path and make it absolute
_dir_path = sys.argv[2] if len(sys.argv) > 2 else "build/web"
DIRECTORY = os.path.abspath(_dir_path)

class SPAHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler that serves index.html for all routes (SPA routing)"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Add CORS headers for development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        
        # Disable caching for OAuth callbacks and index.html to ensure fresh content
        # This is critical for OAuth flows where each callback must be processed
        if '/auth/callback' in self.path or self.path.endswith('/index.html') or self.path == '/':
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Expires', '0')
        
        super().end_headers()
    
    def do_GET(self):
        # Translate the URL path to a file system path
        file_path = self.translate_path(self.path)
        
        # Check if it's a file that exists
        if os.path.isfile(file_path):
            return super().do_GET()
        
        # Check if it's a directory that exists (serve index.html from it)
        if os.path.isdir(file_path):
            index_path = os.path.join(file_path, 'index.html')
            if os.path.isfile(index_path):
                self.path = self.path.rstrip('/') + '/index.html'
                return super().do_GET()
        
        # Otherwise, serve root index.html for SPA routing
        original_path = self.path
        self.path = '/index.html'
        try:
            return super().do_GET()
        finally:
            self.path = original_path

if __name__ == "__main__":
    # Verify the directory exists
    if not os.path.exists(DIRECTORY):
        print(f"❌ Error: Directory not found: {DIRECTORY}")
        sys.exit(1)
    
    if not os.path.isdir(DIRECTORY):
        print(f"❌ Error: Not a directory: {DIRECTORY}")
        sys.exit(1)
    
    with socketserver.TCPServer(("0.0.0.0", PORT), SPAHTTPRequestHandler) as httpd:
        print(f"Serving HTTP on 0.0.0.0 port {PORT} (http://0.0.0.0:{PORT}/) ...")
        print(f"Serving directory: {DIRECTORY}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")

