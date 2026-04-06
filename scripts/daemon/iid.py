#!/usr/bin/env python3
"""iid — ii daemon: backend service for iNiR desktop shell.

Asyncio Unix socket server providing system-level settings (display,
input) to Quickshell clients via JSON-line protocol.

Socket: $XDG_RUNTIME_DIR/iid.sock
Protocol: one JSON object per line (newline-delimited)
  Request:  {"method": "module.action", "params": {...}, "id": 1}
  Response: {"result": {...}, "id": 1}  or  {"error": "message", "id": 1}
  Event:    {"event": "module.event_name", "data": {...}}
"""

import asyncio
import json
import logging
import os
import signal
import sys
from pathlib import Path
from typing import Any, Callable, Coroutine

log = logging.getLogger("iid")

# Type alias for method handlers
MethodHandler = Callable[[dict, Any], Coroutine[Any, Any, Any]]


class Server:
    """Main iid server — manages socket, clients, module registry."""

    def __init__(self, socket_path: Path) -> None:
        self.socket_path = socket_path
        self.registry: dict[str, MethodHandler] = {}
        self.clients: set[ClientHandler] = set()
        self._server: asyncio.Server | None = None

    def broadcast(self, message: dict) -> None:
        """Push an event to all connected clients."""
        line = json.dumps(message, separators=(",", ":"))
        dead: list[ClientHandler] = []
        for client in self.clients:
            try:
                client.writer.write(line.encode() + b"\n")
            except Exception:
                dead.append(client)
        for client in dead:
            self.clients.discard(client)

    async def _handle_connection(
        self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter
    ) -> None:
        client = ClientHandler(reader, writer, self)
        self.clients.add(client)
        peer = writer.get_extra_info("peername") or "unix-client"
        log.info("Client connected: %s (total: %d)", peer, len(self.clients))
        try:
            await client.run()
        finally:
            self.clients.discard(client)
            try:
                writer.close()
                await writer.wait_closed()
            except Exception:
                pass
            log.info("Client disconnected: %s (total: %d)", peer, len(self.clients))

    def load_modules(self) -> None:
        """Import and register all iid_* modules from the same directory."""
        import importlib

        # Add our directory to sys.path so modules can import each other
        daemon_dir = str(Path(__file__).parent)
        if daemon_dir not in sys.path:
            sys.path.insert(0, daemon_dir)

        module_names = ["iid_display", "iid_input", "iid_keybinds"]
        for name in module_names:
            try:
                mod = importlib.import_module(name)
                mod.register(self.registry)
            except Exception:
                log.exception("Failed to load module %s", name)

        log.info(
            "Loaded %d methods: %s",
            len(self.registry),
            ", ".join(sorted(self.registry)),
        )

    async def start(self) -> None:
        """Bind the socket and start serving."""
        # Clean stale socket
        if self.socket_path.exists():
            log.info("Removing stale socket: %s", self.socket_path)
            self.socket_path.unlink()

        self._server = await asyncio.start_unix_server(
            self._handle_connection, path=str(self.socket_path)
        )
        # Ensure socket is readable/writable by owner
        self.socket_path.chmod(0o700)

        log.info("iid listening on %s", self.socket_path)

    async def stop(self) -> None:
        """Graceful shutdown."""
        log.info("Shutting down...")
        if self._server:
            self._server.close()
            await self._server.wait_closed()

        # Close all client connections
        for client in list(self.clients):
            try:
                client.writer.close()
            except Exception:
                pass
        self.clients.clear()

        # Remove socket file
        if self.socket_path.exists():
            self.socket_path.unlink()
            log.info("Removed socket: %s", self.socket_path)

    async def serve_forever(self) -> None:
        """Run until stopped by signal."""
        if self._server is None:
            raise RuntimeError("Server not started")

        loop = asyncio.get_running_loop()
        stop_event = asyncio.Event()

        def _signal_handler() -> None:
            log.info("Signal received, stopping...")
            stop_event.set()

        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(sig, _signal_handler)

        await stop_event.wait()
        await self.stop()


class ClientHandler:
    """Handles a single client connection — reads JSON lines, dispatches to modules."""

    def __init__(
        self,
        reader: asyncio.StreamReader,
        writer: asyncio.StreamWriter,
        server: Server,
    ) -> None:
        self.reader = reader
        self.writer = writer
        self.server = server

    async def run(self) -> None:
        """Read lines until EOF or error."""
        while True:
            try:
                line = await self.reader.readline()
            except (ConnectionResetError, BrokenPipeError):
                break

            if not line:
                break  # EOF

            line_str = line.decode("utf-8", errors="replace").strip()
            if not line_str:
                continue

            await self._dispatch(line_str)

    async def _dispatch(self, line: str) -> None:
        """Parse a JSON-line request and call the appropriate handler."""
        try:
            request = json.loads(line)
        except json.JSONDecodeError as e:
            self._send({"error": f"Invalid JSON: {e}", "id": None})
            return

        req_id = request.get("id")
        method = request.get("method")
        params = request.get("params", {})

        if not method:
            self._send({"error": "Missing 'method' field", "id": req_id})
            return

        handler = self.server.registry.get(method)
        if handler is None:
            self._send({"error": f"Unknown method: {method}", "id": req_id})
            return

        try:
            result = await handler(params, self.server)
            self._send({"result": result, "id": req_id})
        except Exception as e:
            log.exception("Error in %s", method)
            self._send({"error": str(e), "id": req_id})

    def _send(self, response: dict) -> None:
        """Write a JSON-line response."""
        try:
            line = json.dumps(response, separators=(",", ":"))
            self.writer.write(line.encode() + b"\n")
        except Exception:
            pass  # Client gone


def get_socket_path() -> Path:
    """Get the socket path from XDG_RUNTIME_DIR."""
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
    if not runtime_dir:
        raise RuntimeError("XDG_RUNTIME_DIR not set")
    return Path(runtime_dir) / "iid.sock"


def main() -> None:
    """Entry point."""
    logging.basicConfig(
        level=logging.INFO,
        format="[iid] %(levelname)s %(name)s: %(message)s",
        stream=sys.stderr,
    )

    socket_path = get_socket_path()
    server = Server(socket_path)
    server.load_modules()

    async def _run() -> None:
        await server.start()
        await server.serve_forever()

    try:
        asyncio.run(_run())
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
