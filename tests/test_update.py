import os
import shlex
import signal
import subprocess
import time
from support import Installation, SHELLS, REVISION


class UpdateTests(Installation):
    def test_queued_startup_checks_recheck_cache_after_locking(self):
        for shell in SHELLS:
            self.requests.unlink(missing_ok=True)
            (self.state / "checked_at").unlink(missing_ok=True)
            result = self.run_shell('''
. "$GCR_LIB_DIR/update.sh"
gcr_check_update --if-due || exit
gcr_check_update --if-due || exit
gcr check
''', shell)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(len(self.logs(self.requests)), 2)

    def test_concurrent_update_is_rejected_before_downloading(self):
        self.env["GCR_TEST_FAILURE"] = "all"
        self.env["GCR_TEST_DELAY"] = "1"
        command = '. ' + shlex.quote(str(self.root / ".ohmyshell")) + '; gcr update --no-restart'
        process = subprocess.Popen([SHELLS[-1], "-f", "-c", command], env=self.env,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            self.wait_for(lambda: (self.state / "download.lock/pid").exists())
            result = self.run_shell("gcr update --no-restart")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("another GCR update", result.stdout)
        finally:
            process.communicate(timeout=5)
        self.assertEqual(len(self.logs(self.requests)), 1)

    def test_terminated_write_is_restored_and_unlocks(self):
        original = self.target(".ohmyprint").read_bytes()
        marker = self.area / "writing"
        self.env["GCR_TEST_MARKER"] = str(marker)
        command = '. ' + shlex.quote(str(self.root / ".ohmyshell")) + '''
. "$GCR_LIB_DIR/transaction.sh"
gcr_apply_payload() {
    command cat "$1/.ohmyprint" > "$GCR_INSTALL_ROOT/.ohmyprint"
    printf ready > "$GCR_TEST_MARKER"
    sleep 10
}
gcr_install_payload "$GCR_TEST_RELEASE" "$GCR_TEST_REVISION"
'''
        process = subprocess.Popen([SHELLS[-1], "-f", "-c", command], env=self.env,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   start_new_session=True)
        try:
            self.wait_for(marker.exists)
            os.killpg(process.pid, signal.SIGTERM)
            process.communicate(timeout=5)
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.communicate()
        self.assertEqual(self.target(".ohmyprint").read_bytes(), original)
        self.assertFalse((self.state / "pending").exists())
        self.assertFalse((self.state / "update.lock").exists())

    def test_disabled_check_never_fetches(self):
        for shell in SHELLS:
            result = self.run_shell("printf ready", shell, interactive=True)
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.logs(self.requests), [])

    def test_startup_is_background_and_throttled(self):
        self.env.update(CHECK_GCR_UPDATE="true", GCR_TEST_DELAY="1")
        started = time.monotonic()
        result = self.run_shell("printf ready", interactive=True)
        self.assertIn("ready", result.stdout)
        self.assertLess(time.monotonic() - started, 0.8)
        self.wait_for(lambda: (self.state / "check_result").exists())
        for shell in SHELLS:
            self.run_shell("printf ready", shell, interactive=True)
        self.assertEqual(len(self.logs(self.requests)), 1)
        self.assertEqual((self.state / "latest").read_text().strip(), REVISION)

    def test_failed_check_records_attempt_and_preserves_cached_version(self):
        self.env["GCR_TEST_FAILURE"] = "all"
        (self.state / "latest").write_text("c" * 40 + "\n")
        result = self.run_shell("gcr check")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.state / "check_result").read_text().strip(), "failed")
        self.env["CHECK_GCR_UPDATE"] = "true"
        self.run_shell("printf ready", interactive=True)
        self.assertEqual(len(self.logs(self.requests)), 1)
        self.assertEqual((self.state / "latest").read_text().strip(), "c" * 40)

    def test_failed_download_does_not_change_any_installed_file(self):
        before = {name: self.target(name).read_bytes() for name in self.paths}
        self.env["GCR_TEST_FAILURE"] = ".ohmytool"
        result = self.run_shell("gcr update --no-restart")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("were not changed", result.stdout)
        self.assertEqual(before, {name: self.target(name).read_bytes() for name in self.paths})

    def test_checksum_mismatch_aborts_before_writing(self):
        (self.remote / ".ohmyprint").write_text("# Corrupt download.\n")
        original = self.target(".ohmyshell").read_bytes()
        result = self.run_shell("gcr update --no-restart")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("checksum mismatch", result.stdout)
        self.assertEqual(self.target(".ohmyshell").read_bytes(), original)

    def test_fixed_revision_and_symlink_survive_update_and_rollback(self):
        for shell in SHELLS:
            with self.subTest(shell=shell):
                config = self.target(".ohmyprint")
                original = config.read_bytes()
                backing = self.area / "cloud-config"
                backing.write_bytes(original)
                config.unlink()
                config.symlink_to(backing)
                inode = backing.stat().st_ino
                result = self.run_shell("gcr update --no-restart", shell)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertTrue(config.is_symlink())
                self.assertEqual(backing.stat().st_ino, inode)
                self.assertEqual(backing.read_bytes(), (self.remote / ".ohmyprint").read_bytes())
                for url in self.logs(self.requests):
                    self.assertTrue("/commits/" in url or "/" + REVISION + "/" in url)
                result = self.run_shell("gcr rollback", shell)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertTrue(config.is_symlink())
                self.assertEqual(backing.read_bytes(), original)

    def test_write_failure_restores_all_contents(self):
        before = {name: self.target(name).read_bytes() for name in self.paths}
        result = self.run_shell('''
. "$GCR_LIB_DIR/transaction.sh"
gcr_apply_payload() {
    command cat "$1/.ohmyprint" > "$GCR_INSTALL_ROOT/.ohmyprint"
    return 23
}
gcr_install_payload "$GCR_TEST_RELEASE" "$GCR_TEST_REVISION"
''')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(before, {name: self.target(name).read_bytes() for name in self.paths})
        self.assertFalse((self.state / "pending").exists())
        self.assertFalse((self.state / "update.lock").exists())

    def test_incomplete_restore_can_be_recovered_later(self):
        original = self.target(".ohmyprint").read_bytes()
        result = self.run_shell('''
. "$GCR_LIB_DIR/transaction.sh"
gcr_apply_payload() {
    command cat "$1/.ohmyprint" > "$GCR_INSTALL_ROOT/.ohmyprint"
    return 23
}
gcr_restore() { return 24; }
gcr_install_payload "$GCR_TEST_RELEASE" "$GCR_TEST_REVISION"
''')
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((self.state / "pending").exists())
        result = self.run_shell("gcr rollback")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.target(".ohmyprint").read_bytes(), original)
        self.assertFalse((self.state / "pending").exists())
