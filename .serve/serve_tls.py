#!/usr/bin/env python3
"""Boo Knight LAN server: HTTPS wrapper over http.server (MC 11612).
Godot 4 web builds require a secure context; http://LAN-IP is not one.
Self-signed cert (SAN IP:192.168.5.231) => browsers warn once, then serve."""
import http.server, ssl, sys, os
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web"))
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8792
srv = http.server.ThreadingHTTPServer(("0.0.0.0", port), http.server.SimpleHTTPRequestHandler)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
base = os.path.dirname(os.path.abspath(__file__))
ctx.load_cert_chain(os.path.join(base, "lan.crt"), os.path.join(base, "lan.key"))
srv.socket = ctx.wrap_socket(srv.socket, server_side=True)
print(f"serving https://0.0.0.0:{port}/")
srv.serve_forever()
