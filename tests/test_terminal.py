import fcntl
import os
from pathlib import Path
import pty
import re
import select
import shlex
import signal
import struct
import termios
import time
from support import Installation, SHELLS


class TerminalTests(Installation):
    def menu(self, shell, command, keys):
        code = '. ' + shlex.quote(str(self.root / ".ohmyshell")) + '''
printf 'BEGIN\\n'
''' + command + '''
code=$?
printf '\\nRESULT=%s:%s:%s\\n' "$code" "$UI_CHOICE" "$UI_PICKS"
'''
        pid, descriptor = pty.fork()
        if pid == 0:
            flags = ["-f"] if Path(shell).name == "zsh" else ["--noprofile", "--norc"]
            os.execve(shell, [shell] + flags + ["-c", code], self.env)
        fcntl.ioctl(descriptor, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
        before = termios.tcgetattr(descriptor)[3]
        output = b""
        deadline = time.monotonic() + 5
        pending = list(keys)
        next_key = float("inf")
        try:
            while time.monotonic() < deadline:
                ready, _, _ = select.select([descriptor], [], [], 0.02)
                if ready:
                    try:
                        block = os.read(descriptor, 65536)
                    except OSError:
                        break
                    if not block:
                        break
                    output += block
                    if b"BEGIN" in output and next_key == float("inf"):
                        next_key = time.monotonic() + 0.1
                    if re.search(rb"RESULT=[^\r\n]*[\r\n]", output):
                        break
                if pending and time.monotonic() >= next_key:
                    os.write(descriptor, pending.pop(0))
                    next_key = time.monotonic() + 0.1
            after = termios.tcgetattr(descriptor)[3]
            mask = termios.ECHO | termios.ICANON | termios.ISIG
            self.assertEqual(before & mask, after & mask)
        finally:
            child, _ = os.waitpid(pid, os.WNOHANG)
            if not child:
                os.kill(pid, signal.SIGKILL)
                os.waitpid(pid, 0)
            os.close(descriptor)
        match = re.search(rb"RESULT=([^\r\n]*)", output)
        self.assertIsNotNone(match, output.decode(errors="replace"))
        return match.group(1).decode()

    def test_navigation_search_selection_and_cancellation(self):
        items = '"alpha|first" "beta|second" "gamma|third"'
        cases = [
            ("ui_menu Test menu " + items, [b"\x1b[B", b"\r"], "0:2:"),
            ("ui_menu Test menu " + items, [b"\x1bOB", b"\r"], "0:2:"),
            ("ui_menu Test menu " + items, [b"/", b"g", b"a", b"\r"], "0:3:"),
            ("ui_choose Test menu " + items, [b"a", b"\r"], "0:1:1 2 3"),
            ("ui_menu Test menu " + items, [b"\x03"], "1:0:"),
        ]
        for shell in SHELLS:
            for command, keys, expected in cases:
                with self.subTest(shell=shell, keys=keys):
                    self.assertEqual(self.menu(shell, command, keys), expected)
