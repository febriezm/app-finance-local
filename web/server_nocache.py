import http.server
import socketserver
import os
import socket

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
DIRECTORY = os.path.join(PROJECT_DIR, "build", "web")

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

class NoCacheHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

def run_server(port=8085):
    local_ip = get_local_ip()
    socketserver.TCPServer.allow_reuse_address = True
    try:
        with socketserver.TCPServer(("", port), NoCacheHTTPRequestHandler) as httpd:
            print("=" * 60)
            print("  MyFinance Web Server Aktif!")
            print("=" * 60)
            print(f"  * Akses dari PC / Komputer : http://localhost:{port}")
            print(f"  * Akses dari HP / iPhone    : http://{local_ip}:{port}")
            print("=" * 60)
            print("  Tekan Ctrl + C di jendela ini untuk mematikan server.")
            print("=" * 60)
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer dihentikan.")
    except Exception as e:
        print(f"\nGagal menjalankan server di port {port}: {e}")

if __name__ == "__main__":
    run_server(8085)
