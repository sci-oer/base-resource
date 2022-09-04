import os
from http.server import (
    HTTPServer,
    BaseHTTPRequestHandler,
    SimpleHTTPRequestHandler,
    ThreadingHTTPServer,
)
import urllib.request as request
import socket  # For gethostbyaddr()
import sys

public_server_url = None

class MyHandler(SimpleHTTPRequestHandler):
    def send_error(self, code, message=None):
        if code == 404:
            if public_server_url:
                self.log_message(f"Page not found, checking on the public web server.")
                try:
                    r = request.urlopen(f"{public_server_url}{self.path}")

                    if r.code == 200:
                        self.send_response(307)
                        self.send_header("Location", f"{public_server_url}{self.path}")
                        self.end_headers()
                        return
                    else:
                        self.log_message(
                            f'Page "{self.path}" not found on the online server status: {r.code}'
                        )
                except Exception as e:
                    self.log_message(f"Failed to check upstream server: {e}.")

        SimpleHTTPRequestHandler.send_error(self, code, message)


def _get_best_family(*address):
    infos = socket.getaddrinfo(
        *address,
        type=socket.SOCK_STREAM,
        flags=socket.AI_PASSIVE,
    )
    family, type, proto, canonname, sockaddr = next(iter(infos))
    return family, sockaddr


def test(
    HandlerClass=BaseHTTPRequestHandler,
    ServerClass=ThreadingHTTPServer,
    protocol="HTTP/1.0",
    port=8000,
    bind=None,
):
    """Test the HTTP request handler class.
    This runs an HTTP server on port 8000 (or the port argument).
    """
    ServerClass.address_family, addr = _get_best_family(bind, port)
    HandlerClass.protocol_version = protocol
    with ServerClass(addr, HandlerClass) as httpd:
        host, port = httpd.socket.getsockname()[:2]
        url_host = f"[{host}]" if ":" in host else host
        print(f"Serving HTTP on {host} port {port} " f"(http://{url_host}:{port}/) ...")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nKeyboard interrupt received, exiting.")
            sys.exit(0)


if __name__ == "__main__":
    import argparse
    import contextlib

    parser = argparse.ArgumentParser(description="Custom webserver wrapper")
    parser.add_argument(
        "--proxy-url",
        type=str,
        metavar="url",
        help="The URL that includes the static lecture content that can be used in lite images",
    )
    parser.add_argument(
        "-b",
        "--bind",
        metavar="ADDRESS",
        help="bind to this address " "(default: all interfaces)",
    )
    parser.add_argument(
        "-d",
        "--directory",
        default=os.getcwd(),
        help="serve this directory " "(default: current directory)",
    )
    parser.add_argument(
        "-p",
        "--protocol",
        metavar="VERSION",
        default="HTTP/1.0",
        help="conform to this HTTP version " "(default: %(default)s)",
    )
    parser.add_argument(
        "port",
        default=8000,
        type=int,
        nargs="?",
        help="bind to this port " "(default: %(default)s)",
    )
    args = parser.parse_args()

    public_server_url = args.proxy_url

    # ensure dual-stack is not disabled; ref #38907
    class DualStackServer(ThreadingHTTPServer):
        def server_bind(self):
            # suppress exception when protocol is IPv4
            with contextlib.suppress(Exception):
                self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
            return super().server_bind()

        def finish_request(self, request, client_address):
            self.RequestHandlerClass(
                request, client_address, self, directory=args.directory
            )

    test(
        HandlerClass=MyHandler,
        ServerClass=DualStackServer,
        port=args.port,
        bind=args.bind,
        protocol=args.protocol,
    )
