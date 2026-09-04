import json
import shlex
import subprocess
from support import Installation, REPO, SHELLS


class RuntimeTests(Installation):
    def test_safe_rm_alias_uses_the_selected_installation(self):
        executable = self.root / ".safe-rm"
        executable.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$GCR_TEST_CALLS"\n')
        executable.chmod(0o755)
        for shell in SHELLS:
            result = self.run_shell('''
if [ -n "${BASH_VERSION:-}" ]; then shopt -s expand_aliases; fi
# Parse the command after startup, as an interactive prompt does.
eval "rm 'file with spaces'"
''', shell)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(self.logs(self.calls), ["file with spaces"])

    def test_reloading_runtime_keeps_lazy_commands_callable(self):
        for shell in SHELLS:
            result = self.run_shell('''
gcr_load_tools || exit
. "$GCR_INSTALL_ROOT/.ohmyshell" || exit
ohmytool --list || exit
new_vps_help
''', shell)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("install_aicoding", result.stdout)

    def test_installer_quotes_paths_and_preserves_noninteractive_login_commands(self):
        root = self.area / 'installation "quoted" $() `touch unwanted`'
        binary = root / "zsh/bin/zsh"
        binary.parent.mkdir(parents=True)
        binary.write_text('#!/bin/sh\nif [ "${1:-}" = -n ]; then exec ' +
                          shlex.quote(SHELLS[-1]) + ' "$@"; fi\nexit 49\n')
        binary.chmod(0o755)
        environment = self.env.copy()
        environment.update({"GCR_TARGET": "ubuntu-nosudo", "GCR_INSTALL_ROOT": str(root)})
        result = subprocess.run(
            ["sh", str(REPO / "install_gcr.sh")], env=environment,
            cwd=self.area, capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for profile in (".bash_profile", ".zshrc"):
            result = subprocess.run(
                [SHELLS[0], "--noprofile", "--norc", "-c",
                 '. "$1"; printf "continued\\n"', "bash", str(root / profile)],
                env=environment, cwd=self.area, capture_output=True, text=True, timeout=10,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("continued", result.stdout)
            self.assertNotIn("No such file", result.stderr)
        self.assertFalse((self.area / "unwanted").exists())

    def test_saved_settings_preserve_symlinks_and_literal_values(self):
        config = self.area / "config.sh"
        cloud_config = self.area / "cloud-config"
        cloud_config.write_text("# Existing user settings.\n")
        config.symlink_to(cloud_config)
        self.env["GCR_TEST_VALUE"] = str(self.area / 'literal "quotes" \\ $() `touch unwanted`')
        for shell in SHELLS:
            result = self.run_shell('''
gcr_load_tools || exit
gcr_save_setting SAFE_RM_TRASH "$GCR_TEST_VALUE" || exit
gcr_save_setting SAFE_RM_TRASH another || exit
gcr_save_setting SAFE_RM_TRASH "$GCR_TEST_VALUE" || exit
. "$GCR_CONFIG_FILE"
[ "$SAFE_RM_TRASH" = "$GCR_TEST_VALUE" ]
''', shell)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(config.is_symlink())
        self.assertTrue(cloud_config.read_text().startswith("# Existing user settings."))
        self.assertFalse((self.area / "unwanted").exists())

    def test_partial_installer_download_is_never_executed(self):
        self.env["GCR_TEST_INSTALLER_URL"] = "https://example.invalid/install.sh"
        self.env["GCR_TEST_INSTALLER_SCRIPT"] = 'touch "$GCR_INSTALL_ROOT/executed"\n'
        self.env["GCR_TEST_PARTIAL_DOWNLOAD"] = "1"
        for shell in SHELLS:
            result = self.run_shell('''
gcr_load_tools || exit
gcr_run_installer "$GCR_TEST_INSTALLER_URL" sh
''', shell)
            self.assertEqual(result.returncode, 22, result.stdout + result.stderr)
            self.assertFalse((self.root / "executed").exists())

    def test_ai_installer_failure_is_not_hidden_by_existing_binary(self):
        self.env["GCR_TEST_INSTALLER_URL"] = "https://claude.ai/install.sh"
        self.env["GCR_TEST_INSTALLER_SCRIPT"] = "exit 47\n"
        for shell in SHELLS:
            result = self.run_shell('''
gcr_load_tools || exit
aicoding_bin() { return 0; }
aicoding_install claude
''', shell)
            self.assertEqual(result.returncode, 47, result.stdout + result.stderr)
            self.assertNotIn("installed at", result.stdout)

    def test_single_tool_menu_propagates_failure(self):
        for shell in SHELLS:
            result = self.run_shell('''
gcr_load_tools || exit
_ohmytool_collect() { OHMYTOOL_ITEMS=("install_example|Example"); }
gcr_install() { return 48; }
_ohmytool_pick example
''', shell)
            self.assertEqual(result.returncode, 48, result.stdout + result.stderr)

    def test_unrelated_library_directory_does_not_override_runtime(self):
        (self.root / "lib").mkdir()
        result = self.run_shell("gcr status")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_tools_are_lazy_and_profiles_can_be_previewed(self):
        for shell in SHELLS:
            result = self.run_shell('''
printf 'loaded=%s\n' "${GCR_TOOLS_LOADED:-0}"
gcr profile workstation --dry-run
printf 'loaded=%s\n' "${GCR_TOOLS_LOADED:-0}"
''', shell)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.count("loaded=0"), 2)
            self.assertIn("install_tssh", result.stdout)
        self.assertEqual(self.logs(self.requests), [])
        self.assertEqual(self.logs(self.calls), [])

    def test_catalog_and_direct_installers_load(self):
        for shell in SHELLS:
            result = self.run_shell('''
gcr_load_tools || exit
while IFS='|' read -r name remainder; do
    command -v "$name" >/dev/null || exit 3
done <<EOF
$GCR_TOOL_CATALOG
EOF
ohmytool --list
''', shell)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("install_aicoding", result.stdout)

    def test_invalid_install_directory_cannot_overwrite_current_service(self):
        current = self.area / "nginx-proxy"
        current.mkdir()
        config = current / "docker-compose.yml"
        config.write_text("original service\n")
        result = self.run_shell("gcr_load_tools && install_nginxproxy", input=str(self.area / "missing") + "\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(config.read_text(), "original service\n")
        self.assertEqual(self.logs(self.requests), [])
        self.assertEqual(self.logs(self.calls), [])

    def test_compose_failure_is_reported_and_directory_is_preserved(self):
        self.env["GCR_TEST_COMPOSE_FAIL"] = "42"
        result = self.run_shell('''
gcr_load_tools
before=$PWD
install_nginxproxy
code=$?
printf 'result=%s unchanged=%s\n' "$code" "$([ "$PWD" = "$before" ] && printf yes)"
exit "$code"
''', input="\n")
        self.assertEqual(result.returncode, 42, result.stdout + result.stderr)
        self.assertIn("unchanged=yes", result.stdout)
        self.assertNotIn("nginx-proxy started", result.stdout)

    def test_existing_compose_configuration_is_not_downloaded_again(self):
        service = self.area / "services/nginx-proxy"
        service.mkdir(parents=True)
        config = service / "docker-compose.yml"
        config.write_text("original service\n")
        result = self.run_shell("gcr_load_tools && install_nginxproxy", input="\n")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(config.read_text(), "original service\n")
        self.assertEqual(self.logs(self.requests), [])

    def test_environment_kernel_uses_created_environment(self):
        for shell in SHELLS:
            self.calls.unlink(missing_ok=True)
            result = self.run_shell("cenv", shell, input="research\n3.12\n")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            calls = [json.loads(line) for line in self.logs(self.calls)]
            self.assertIn(["conda", "run", "--name", "research", "python", "-m",
                           "ipykernel", "install", "--user", "--name", "research"], calls)

    def test_failed_environment_creation_does_not_register_kernel(self):
        self.env["GCR_TEST_CREATE_FAIL"] = "1"
        result = self.run_shell("cenv", input="research\n3.12\n")
        self.assertEqual(result.returncode, 41, result.stdout + result.stderr)
        calls = [json.loads(line) for line in self.logs(self.calls)]
        self.assertFalse(any(call[:2] == ["conda", "run"] for call in calls))

    def test_duplicate_environment_names_use_selected_prefix(self):
        prefixes = [str(self.area / "first shared/env"), str(self.area / "second shared/env")]
        self.env["GCR_TEST_ENVS"] = json.dumps({"envs": prefixes})
        for shell in SHELLS:
            result = self.run_shell("env", shell, input="2\n")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            call = json.loads(self.logs(self.calls)[-1])
            self.assertEqual(call, ["conda", "activate", prefixes[1]])

    def test_doctor_reports_broken_symlink_without_changing_it(self):
        file = self.target(".ohmytool")
        file.unlink()
        file.symlink_to(self.area / "missing-file")
        result = self.run_shell("gcr doctor")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("broken symlink", result.stdout)
        self.assertTrue(file.is_symlink())
        self.assertEqual(self.logs(self.requests), [])

    def test_doctor_reports_kernel_environment_mismatch(self):
        prefix = self.area / "envs/research"
        self.env["GCR_TEST_ENVS"] = json.dumps({"envs": [str(prefix)]})
        self.env["GCR_TEST_KERNELS"] = json.dumps({"kernelspecs": {
            "research": {"spec": {"argv": ["/bin/sh", "-m", "ipykernel"]}}
        }})
        result = self.run_shell("gcr doctor")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not match environment", result.stdout)

    def test_argument_boundaries_survive_spinner(self):
        destination = self.area / "file with ' quotes"
        self.env["GCR_TEST_OUTPUT"] = str(destination)
        result = self.run_shell('''
ui_spin test python3 -c 'import pathlib,sys; pathlib.Path(sys.argv[1]).write_text(sys.argv[2])' \
    "$GCR_TEST_OUTPUT" 'literal $() ; and spaces'
''')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(destination.read_text(), "literal $() ; and spaces")

    def test_installer_preserves_profile_and_user_config_symlinks(self):
        profile = self.root / ".zshrc"
        backing = self.area / "cloud-zshrc"
        backing.write_text("export CUSTOM_SETTING=preserved\n")
        profile.symlink_to(backing)
        user_config = self.area / "config.sh"
        cloud_config = self.area / "cloud-config"
        cloud_config.write_text("CHECK_GCR_UPDATE=false\n")
        user_config.symlink_to(cloud_config)
        environment = self.env.copy()
        environment["GCR_TARGET"] = "macos"
        # This target only checks for zsh; it performs no package or login-shell changes.
        result = subprocess.run(
            ["sh", str(REPO / "install_gcr.sh")], env=environment,
            cwd=self.area, capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(profile.is_symlink())
        self.assertIn("CUSTOM_SETTING=preserved", backing.read_text())
        self.assertTrue(user_config.is_symlink())
        self.assertEqual(cloud_config.read_text(), "CHECK_GCR_UPDATE=false\n")
