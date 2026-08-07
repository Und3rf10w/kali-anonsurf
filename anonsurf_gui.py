#!/usr/bin/env python3
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gdk, Pango
import subprocess
import threading
import re
import http.client
import ssl

CSS = b"""
window { background-color: #0d0d0d; }
#title { color: #00ff41; font-size: 22px; font-weight: bold; }
#subtitle { color: #555; font-size: 11px; }
#status_box { background-color: #111; border-radius: 8px; padding: 10px; }
#status_label { font-size: 13px; font-weight: bold; }
#ip_label { color: #aaa; font-size: 12px; }
#log_view { background-color: #0a0a0a; color: #00ff41; font-family: monospace; font-size: 11px; }
#log_scroll { border: 1px solid #222; }
button { background-color: #1a1a1a; color: #00ff41; border: 1px solid #00ff41;
         border-radius: 5px; padding: 8px 14px; font-weight: bold; }
button:hover { background-color: #00ff41; color: #0d0d0d; }
#btn_stop { border-color: #ff4444; color: #ff4444; }
#btn_stop:hover { background-color: #ff4444; color: #0d0d0d; }
#btn_change { border-color: #ffaa00; color: #ffaa00; }
#btn_change:hover { background-color: #ffaa00; color: #0d0d0d; }
#btn_pandora { border-color: #ff0066; color: #ff0066; }
#btn_pandora:hover { background-color: #ff0066; color: #0d0d0d; }
separator { background-color: #222; }
"""

class AnonSurfGUI(Gtk.Window):
    def __init__(self):
        super().__init__(title="AnonSurf GUI")
        self.set_default_size(620, 520)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Apply CSS
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        root.set_margin_top(16)
        root.set_margin_bottom(16)
        root.set_margin_start(20)
        root.set_margin_end(20)
        self.add(root)

        # Title
        title = Gtk.Label(label="☠  AnonSurf")
        title.set_name("title")
        root.pack_start(title, False, False, 0)

        sub = Gtk.Label(label="Transparent TOR proxy — Kali Linux")
        sub.set_name("subtitle")
        root.pack_start(sub, False, False, 0)

        root.pack_start(Gtk.Separator(), False, False, 4)

        # Status row
        status_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        status_box.set_name("status_box")
        status_box.set_halign(Gtk.Align.CENTER)

        self.dot = Gtk.Label(label="●")
        self.dot.set_name("status_label")
        status_box.pack_start(self.dot, False, False, 0)

        self.status_label = Gtk.Label(label="Checking...")
        self.status_label.set_name("status_label")
        status_box.pack_start(self.status_label, False, False, 0)

        self.ip_label = Gtk.Label(label="")
        self.ip_label.set_name("ip_label")
        status_box.pack_start(self.ip_label, False, False, 8)

        root.pack_start(status_box, False, False, 0)

        root.pack_start(Gtk.Separator(), False, False, 4)

        # Main buttons
        btn_row1 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        btn_row1.set_halign(Gtk.Align.CENTER)

        self.btn_start = self._btn("▶  Start", self._on_start)
        self.btn_stop = self._btn("■  Stop", self._on_stop, name="btn_stop")
        self.btn_restart = self._btn("↺  Restart", self._on_restart)
        self.btn_change = self._btn("⟳  Change ID", self._on_change, name="btn_change")
        self.btn_status = self._btn("?  Status", self._on_status)

        for b in [self.btn_start, self.btn_stop, self.btn_restart, self.btn_change, self.btn_status]:
            btn_row1.pack_start(b, False, False, 0)
        root.pack_start(btn_row1, False, False, 0)

        # I2P + Pandora row
        btn_row2 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        btn_row2.set_halign(Gtk.Align.CENTER)

        btn_starti2p = self._btn("⬡  Start I2P", self._on_starti2p)
        btn_stopi2p  = self._btn("⬡  Stop I2P",  self._on_stopi2p)
        btn_myip     = self._btn("⊙  My IP",     self._on_myip)
        btn_pandora  = self._btn("💣  Pandora Bomb", self._on_pandora, name="btn_pandora")

        for b in [btn_starti2p, btn_stopi2p, btn_myip, btn_pandora]:
            btn_row2.pack_start(b, False, False, 0)
        root.pack_start(btn_row2, False, False, 0)

        root.pack_start(Gtk.Separator(), False, False, 4)

        # Log output
        log_label = Gtk.Label(label="Output Log")
        log_label.set_halign(Gtk.Align.START)
        log_label.set_name("ip_label")
        root.pack_start(log_label, False, False, 0)

        scroll = Gtk.ScrolledWindow()
        scroll.set_name("log_scroll")
        scroll.set_min_content_height(180)
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        self.log_buf = Gtk.TextBuffer()
        self.log_view = Gtk.TextView(buffer=self.log_buf)
        self.log_view.set_name("log_view")
        self.log_view.set_editable(False)
        self.log_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.log_view.set_left_margin(8)
        scroll.add(self.log_view)
        root.pack_start(scroll, True, True, 0)

        # Clear log button
        btn_clear = Gtk.Button(label="Clear Log")
        btn_clear.set_halign(Gtk.Align.END)
        btn_clear.connect("clicked", lambda _: self.log_buf.set_text(""))
        root.pack_start(btn_clear, False, False, 0)

        self.show_all()
        self._refresh_status()

    def _btn(self, label, handler, name=None):
        b = Gtk.Button(label=label)
        if name:
            b.set_name(name)
        b.connect("clicked", handler)
        return b

    def _log(self, text):
        def _append():
            end = self.log_buf.get_end_iter()
            self.log_buf.insert(end, text + "\n")
            # auto-scroll
            adj = self.log_view.get_vadjustment()
            adj.set_value(adj.get_upper())
        GLib.idle_add(_append)

    # Allowlist: only these exact scripts can be executed
    _SCRIPT_MAP = {
        "anonsurf": "/etc/init.d/anonsurf",
        "pandora":  "/etc/init.d/pandora",
    }
    # Allowlist: only these exact arguments are permitted
    _ALLOWED_ARGS = {
        "anonsurf": {"start", "stop", "restart", "change", "status", "myip", "starti2p", "stopi2p"},
        "pandora":  {"bomb"},
    }

    def _run_cmd(self, cmd):
        """Run anonsurf/pandora via pkexec using absolute paths and strict allowlists."""
        binary = cmd[0]
        args   = cmd[1:]

        # Validate binary is in allowlist
        if binary not in self._SCRIPT_MAP:
            self._log(f"[blocked] unknown command: {binary}")
            return
        # Validate each argument against allowlist
        for arg in args:
            if arg not in self._ALLOWED_ARGS.get(binary, set()):
                self._log(f"[blocked] disallowed argument: {arg}")
                return

        script   = self._SCRIPT_MAP[binary]
        real_cmd = ["/usr/bin/pkexec", "/bin/bash", script] + args

        def _worker():
            self._log(f"$ {binary} {' '.join(args)}")
            try:
                # Use communicate() to avoid pipe buffer deadlock
                proc = subprocess.Popen(
                    real_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True
                )
                output, _ = proc.communicate()
                for line in output.splitlines():
                    clean = re.sub(r'\033\[[0-9;]*m', '', line)
                    if clean:
                        self._log(clean)
                self._log(f"[exit code: {proc.returncode}]")
            except Exception as e:
                self._log(f"[error] {e}")
            GLib.idle_add(self._refresh_status)
        threading.Thread(target=_worker, daemon=True).start()

    def _refresh_status(self):
        def _worker():
            try:
                result = subprocess.run(
                    ["pgrep", "-x", "tor"], capture_output=True
                )
                running = result.returncode == 0
            except Exception:
                running = False

            def _update():
                if running:
                    self.dot.set_markup('<span color="#00ff41">●</span>')
                    self.status_label.set_markup('<span color="#00ff41">ACTIVE — Tor is running</span>')
                else:
                    self.dot.set_markup('<span color="#ff4444">●</span>')
                    self.status_label.set_markup('<span color="#ff4444">INACTIVE — Tor is not running</span>')
            GLib.idle_add(_update)

            # Fetch current IP via http.client (avoids urllib.urlopen warning)
            try:
                ctx  = ssl.create_default_context()
                conn = http.client.HTTPSConnection("api.ipify.org", timeout=5, context=ctx)
                conn.request("GET", "/")
                resp = conn.getresponse()
                ip   = resp.read().decode().strip() if resp.status == 200 else "unavailable"
                conn.close()
            except Exception:
                ip = "unavailable"
            GLib.idle_add(lambda: self.ip_label.set_text(f"IP: {ip}"))

        threading.Thread(target=_worker, daemon=True).start()

    def _confirm(self, msg):
        dlg = Gtk.MessageDialog(
            transient_for=self, modal=True,
            message_type=Gtk.MessageType.WARNING,
            buttons=Gtk.ButtonsType.YES_NO,
            text=msg
        )
        resp = dlg.run()
        dlg.destroy()
        return resp == Gtk.ResponseType.YES

    # --- Button handlers ---
    def _on_start(self, _):
        self._run_cmd(["anonsurf", "start"])

    def _on_stop(self, _):
        self._run_cmd(["anonsurf", "stop"])

    def _on_restart(self, _):
        self._run_cmd(["anonsurf", "restart"])

    def _on_change(self, _):
        self._run_cmd(["anonsurf", "change"])

    def _on_status(self, _):
        self._run_cmd(["anonsurf", "status"])

    def _on_starti2p(self, _):
        self._run_cmd(["anonsurf", "starti2p"])

    def _on_stopi2p(self, _):
        self._run_cmd(["anonsurf", "stopi2p"])

    def _on_myip(self, _):
        self._run_cmd(["anonsurf", "myip"])

    def _on_pandora(self, _):
        if self._confirm("⚠ Pandora will WIPE RAM and clear all caches.\nThis will kill SSH sessions and active connections.\n\nAre you sure?"):
            self._run_cmd(["pandora", "bomb"])


if __name__ == "__main__":
    app = AnonSurfGUI()
    app.connect("destroy", Gtk.main_quit)
    Gtk.main()
