"""Isolated installations and local command fixtures for runtime regressions."""
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parent.parent
SHELLS = [shutil.which("bash"), shutil.which("zsh")]
REVISION = "a" * 40


class Installation(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="gcr-test-", dir="/tmp")
        self.area = Path(self.temporary.name)
        self.root = self.area / "installed"
        self.root.mkdir()
        self.remote = self.area / "release"
        self.remote.mkdir()
        self.bin = self.area / "bin"
        self.bin.mkdir()
        self.requests = self.area / "requests"
        self.calls = self.area / "calls"
        self.env = os.environ.copy()
        self.env.update({
            "GCR_INSTALL_ROOT": str(self.root),
            "GCR_CONFIG_FILE": str(self.area / "config.sh"),
            "GCR_STATE_DIR": str(self.area / "state"),
            "GCR_SERVICE_DIR": str(self.area / "services"),
            "GCR_LOAD_THEME": "false",
            "GCR_NO_ANIM": "1",
            "CHECK_GCR_UPDATE": "false",
            "AUTO_GCR_UPDATE": "false",
            "GCR_TEST_RELEASE": str(self.remote),
            "GCR_TEST_REQUESTS": str(self.requests),
            "GCR_TEST_CALLS": str(self.calls),
            "GCR_TEST_REVISION": REVISION,
            "GCR_TEST_FAILURE": "",
            "PATH": str(self.bin) + os.pathsep + self.env["PATH"],
            "TERM": "xterm-256color",
        })
        for key in ("CONDA_PREFIX", "CONDA_DEFAULT_ENV"):
            self.env.pop(key, None)
        output = subprocess.check_output(
            ["sh", "-c", '. "$1/lib/core.sh"; gcr_payload_files', "sh", str(REPO)],
            text=True,
        )
        self.paths = output.splitlines()
        for name in self.paths:
            destination = self.target(name)
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(b"# Previous installation.\n" + (REPO / name).read_bytes())
            remote = self.remote / name
            remote.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO / name, remote)
        shutil.copyfile(REPO / "manifest.sha256", self.remote / "manifest.sha256")
        self.state = Path(self.env["GCR_STATE_DIR"])
        self.state.mkdir()
        (self.state / "revision").write_text("b" * 40 + "\n")
        self.executable("curl", '''
import os, pathlib, sys, time
args = sys.argv[1:]
url = next(arg for arg in args if arg.startswith(("https://", "http://")))
with open(os.environ["GCR_TEST_REQUESTS"], "a") as log:
    log.write(url + "\\n")
time.sleep(float(os.environ.get("GCR_TEST_DELAY", "0")))
failure = os.environ.get("GCR_TEST_FAILURE", "")
if failure and (url.endswith(failure) or failure == "all"):
    raise SystemExit(22)
if "/commits/" in url:
    data = os.environ["GCR_TEST_REVISION"].encode()
elif url == os.environ.get("GCR_TEST_INSTALLER_URL"):
    data = os.environ["GCR_TEST_INSTALLER_SCRIPT"].encode()
elif "/ConfigFile/" in url:
    data = b"services:\\n  example:\\n    image: example\\n"
else:
    name = url.split("/" + os.environ["GCR_TEST_REVISION"] + "/", 1)[1]
    data = (pathlib.Path(os.environ["GCR_TEST_RELEASE"]) / name).read_bytes()
if "-o" in args:
    pathlib.Path(args[args.index("-o") + 1]).write_bytes(data)
else:
    sys.stdout.buffer.write(data)
if os.environ.get("GCR_TEST_PARTIAL_DOWNLOAD"):
    raise SystemExit(22)
''')
        self.executable("conda", '''
import json, os, sys
args = sys.argv[1:]
with open(os.environ["GCR_TEST_CALLS"], "a") as log:
    log.write(json.dumps(["conda"] + args) + "\\n")
if args[:2] == ["env", "list"]:
    print(os.environ.get("GCR_TEST_ENVS", '{"envs": []}'))
elif args[:1] == ["create"] and os.environ.get("GCR_TEST_CREATE_FAIL"):
    raise SystemExit(41)
''')
        self.executable("jupyter", '''
import os
print(os.environ.get("GCR_TEST_KERNELS", '{"kernelspecs": {}}'))
''')
        self.executable("docker", '''
import json, os, sys
with open(os.environ["GCR_TEST_CALLS"], "a") as log:
    log.write(json.dumps(["docker", os.getcwd()] + sys.argv[1:]) + "\\n")
if sys.argv[1:3] == ["compose", "up"]:
    raise SystemExit(int(os.environ.get("GCR_TEST_COMPOSE_FAIL", "0")))
''')

    def tearDown(self):
        self.temporary.cleanup()

    def target(self, name):
        if name.startswith(("lib/", "config/")):
            return self.root / ".gcr" / name
        return self.root / name

    def executable(self, name, code):
        path = self.bin / name
        path.write_text("#!" + sys.executable + "\n" + code)
        path.chmod(0o755)
        return path

    def run_shell(self, code, shell=None, interactive=False, input=None, timeout=15):
        shell = shell or SHELLS[-1]
        flags = ["-f"] if Path(shell).name == "zsh" else ["--noprofile", "--norc"]
        if interactive:
            flags.append("-i")
        setup = ". " + shlex.quote(str(self.root / ".ohmyshell")) + "\n"
        return subprocess.run(
            [shell] + flags + ["-c", setup + code],
            env=self.env, cwd=self.area, input=input, capture_output=True, text=True,
            timeout=timeout,
        )

    def logs(self, path):
        return path.read_text().splitlines() if path.exists() else []

    def wait_for(self, predicate, timeout=5):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(0.03)
        self.fail("Timed out waiting for background work.")
