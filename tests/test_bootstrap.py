"""Bootstrap regressions for existing Oh My Zsh installations."""
import os
from pathlib import Path
import shutil
import stat
import subprocess
import unittest

from support import Installation, REPO


class BootstrapTests(Installation):
    def prepare_source(self):
        shutil.copyfile(REPO / "install_gcr.sh", self.remote / "install_gcr.sh")
        vendor = self.remote / "oh-my-zsh"
        vendor.mkdir()
        (vendor / "oh-my-zsh.sh").write_text("# Bundled shell source.\n")
        return vendor

    def install(self):
        environment = self.env.copy()
        environment["GCR_TARGET"] = "macos"
        return subprocess.run(
            ["sh", str(self.remote / "install_gcr.sh")], env=environment,
            cwd=self.area, capture_output=True, text=True, timeout=30,
        )

    def test_existing_readonly_compilation_caches_are_preserved(self):
        source = self.prepare_source()
        relative = Path("custom/themes/powerlevel10k/internal/p10k.zsh")
        source_file = source / relative
        source_file.parent.mkdir(parents=True)
        source_file.write_text("# Updated theme source.\n")
        # Local checkouts can contain generated caches even when Git ignores them.
        for suffix in (".zwc", ".zwc.old"):
            Path(str(source_file) + suffix).write_text("Foreign compiled cache.\n")
        target = self.root / ".oh-my-zsh" / relative
        target.parent.mkdir(parents=True)
        target.write_text("# Previous theme source.\n")
        cache = Path(str(target) + ".zwc")
        cache.write_text("Machine-local cache.\n")
        cache.chmod(0o444)
        inode = cache.stat().st_ino
        backing = self.area / "linked-cache"
        backing.write_text("Linked machine-local cache.\n")
        backing.chmod(0o444)
        linked = Path(str(target) + ".zwc.old")
        linked.symlink_to(backing)

        result = self.install()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(target.read_bytes(), source_file.read_bytes())
        self.assertEqual(cache.read_text(), "Machine-local cache.\n")
        self.assertEqual(cache.stat().st_ino, inode)
        self.assertEqual(stat.S_IMODE(cache.stat().st_mode), 0o444)
        self.assertTrue(linked.is_symlink())
        self.assertEqual(backing.read_text(), "Linked machine-local cache.\n")
        self.assertEqual(stat.S_IMODE(backing.stat().st_mode), 0o444)

    @unittest.skipIf(os.geteuid() == 0, "Root can overwrite read-only source files.")
    def test_readonly_source_still_fails_without_changing_permissions(self):
        self.prepare_source()
        target = self.root / ".oh-my-zsh/oh-my-zsh.sh"
        target.parent.mkdir(parents=True)
        target.write_text("# User-protected source.\n")
        target.chmod(0o444)
        previous = self.target(".ohmyshell").read_bytes()

        result = self.install()

        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(target.read_text(), "# User-protected source.\n")
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o444)
        self.assertEqual(self.target(".ohmyshell").read_bytes(), previous)
