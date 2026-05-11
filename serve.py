#!/usr/bin/env python3
"""
iBridge Local Development Server
Serves the Website directory on port 8080
"""
import http.server
import socketserver
import os
import sys
from pathlib import Path

# Change to script directory
SCRIPT_DIR = Path(__file__).parent.absolute()
WEBSITE_DIR = SCRIPT_DIR / "Website"

print(f"🚀 iBridge Local Server Starting...")
print(f"📍 Website Root: {WEBSITE_DIR}")

os.chdir(WEBSITE_DIR)

PORT = 8080

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add security headers
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('X-Frame-Options', 'DENY')
        self.send_header('Referrer-Policy', 'strict-origin-when-cross-origin')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()
    
    def do_GET(self):
        if self.path == '/':
            self.path = '/index.html'
        return super().do_GET()

try:
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        print(f"\n✨ iBridge Server Running!")
        print(f"📍 Local URL: http://localhost:{PORT}")
        print(f"📱 Main Site: http://localhost:{PORT}/")
        print(f"👨‍💼 Staff Portal: http://localhost:{PORT}/TicketingSystem/frontend/professional-dashboard.html")
        print(f"🎓 LMS Platform: http://localhost:{PORT}/lms-platform.html")
        print(f"📊 Security Dashboard: http://localhost:{PORT}/security-dashboard.html")
        print(f"\n✅ Press Ctrl+C to stop the server\n")
        httpd.serve_forever()
except OSError as e:
    if e.errno == 48 or e.errno == 98:  # Port already in use
        print(f"❌ Port {PORT} is already in use.")
        print(f"Trying to find an open port...")
        PORT += 1
        with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
            print(f"✨ Server running on port {PORT}")
            print(f"📍 Local URL: http://localhost:{PORT}")
            httpd.serve_forever()
    else:
        print(f"Error: {e}")
        sys.exit(1)
