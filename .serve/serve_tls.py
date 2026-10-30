#!/usr/bin/env python3
"""Boo Knight LAN server (MC 11612): one process, ports 8791+8792.
Godot 4 web builds need a secure context: http://localhost passes, http://LAN-IP
does not. A TLS-only port then traps novices (Chrome remembered their old
http:// habit and typed it -> ERR_CONNECTION_RESET). So this gateway peeks the
first bytes: TLS -> serve the game over https; plain HTTP -> serve it only to
loopback (automated tests) and 301-redirect everyone else to the https port.
Self-signed cert (SAN IP:192.168.5.231): browser warns once, user proceeds once."""
import http.server, mimetypes, os, socket, ssl, sys, threading

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")
HERE = os.path.dirname(os.path.abspath(__file__))
HTTPS_PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8792
HTTP_PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8791
mimetypes.add_type("application/wasm", ".wasm")
CTX = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
CTX.load_cert_chain(os.path.join(HERE, "lan.crt"), os.path.join(HERE, "lan.key"))
LOOPBACK = {"127.0.0.1", "::1", "::ffff:127.0.0.1"}


class Game(http.server.SimpleHTTPRequestHandler):
    """One request per connection (HTTP/1.0 close) from BASE."""
    protocol_version = "HTTP/1.0"

    def __init__(self, sock, addr, srv):
        super().__init__(sock, addr, srv, directory=BASE)

    def log_message(self, *a):
        pass


class Redirect(http.server.BaseHTTPRequestHandler):
    """Plain HTTP from a non-local machine -> 301 to the https port."""
    protocol_version = "HTTP/1.0"

    def do_GET(self):
        host = (self.headers.get("Host") or "").split(":")[0] or "192.168.5.231"
        self.send_response(301)
        self.send_header("Location", f"https://{host}:{HTTPS_PORT}/")
        self.end_headers()

    def log_message(self, *a):
        pass


class Gateway(http.server.BaseHTTPRequestHandler):
    """Peeks 5 bytes: 0x16 = TLS handshake record -> serve game over TLS.
    Plain HTTP: loopback gets the game, everyone else the redirect."""
    protocol_version = "HTTP/1.0"

    def handle(self):
        head = self.connection.recv(5, socket.MSG_PEEK)
        if not head:
            return
        conn = self.connection
        if head[0] == 0x16:
            try:
                conn = CTX.wrap_socket(self.connection, server_side=True)
            except ssl.SSLError:
                return
            inner = Game(conn, self.client_address, self.server)
        elif self.client_address[0] in LOOPBACK:
            inner = Game(conn, self.client_address, self.server)
        else:
            inner = Redirect(conn, self.client_address, self.server)
        try:
            inner.handle()
        finally:
            inner.finish()
            inner.close()
            self.connection = None  # fd already closed by inner; avoid double-close
            self.connected = False

    def log_message(self, *a):
        pass


def serve(port):
    srv = http.server.ThreadingHTTPServer(("0.0.0.0", port), Gateway)
    threading.Thread(target=srv.serve_forever, daemon=True).start()


serve(HTTP_PORT)
serve(HTTPS_PORT)
print(f"Boo Knight: http://{HTTP_PORT} (redirects non-local) + https://{HTTPS_PORT} serving {BASE}")
threading.Event().wait()
