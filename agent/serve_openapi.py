#!/usr/bin/env python3
"""
Simple HTTP server to serve the OpenAPI specification for the ADK API.
This is a workaround for the MCP ClientSession schema generation issue.
"""
import json
import http.server
import socketserver
from pathlib import Path
import argparse

class OpenAPIHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/openapi.json':
            spec_path = Path(__file__).parent / 'openapi_spec.json'
            if spec_path.exists():
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()

                with open(spec_path, 'r') as f:
                    spec = json.load(f)
                self.wfile.write(json.dumps(spec, indent=2).encode())
            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b'OpenAPI spec not found')
        elif self.path == '/' or self.path == '/docs':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

            html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>ADK API Documentation</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script>
        const ui = SwaggerUIBundle({{
            url: 'http://localhost:{PORT}/openapi.json',
            dom_id: '#swagger-ui',
            presets: [SwaggerUIBundle.presets.apis],
        }});
    </script>
</body>
</html>
            """
            self.wfile.write(html.encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not found')

    def log_message(self, format, *args):
        # Suppress default logging
        pass

def main():
    parser = argparse.ArgumentParser(description='Serve ADK OpenAPI specification')
    parser.add_argument('--port', type=int, default=8080, help='Port to serve on')
    args = parser.parse_args()

    global PORT
    PORT = args.port

    with socketserver.TCPServer(("", args.port), OpenAPIHandler) as httpd:
        print(f"Serving ADK OpenAPI spec on port {args.port}")
        print(f"Access documentation at: http://localhost:{args.port}/docs")
        print(f"Direct OpenAPI JSON at: http://localhost:{args.port}/openapi.json")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server...")

if __name__ == '__main__':
    main()

