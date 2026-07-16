import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin" / "ai-run"


class AiRunTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.profiles = self.root / "profiles"
        self.home.mkdir()
        self.profiles.mkdir(mode=0o700)

    def tearDown(self):
        self.temp.cleanup()

    def profile(self, name, content, mode=0o600):
        directory = self.profiles / name
        directory.mkdir(parents=True)
        directory.chmod(0o700)
        path = directory / "env"
        path.write_text(content)
        path.chmod(mode)

    def invoke(self, *args, extra_env=None, profiles_dir=True):
        env = {
            "AI_DEFAULT_PROFILE": "personal",
            "AMBIENT_SECRET": "must-not-leak",
            "HERDR_WORKSPACE_ID": "workspace-test",
            "HOME": str(self.home),
            "PATH": os.environ["PATH"],
        }
        if profiles_dir:
            env["AI_PROFILES_DIR"] = str(self.profiles)
        env.update(extra_env or {})
        command = [
            str(SCRIPT),
            *args,
            "--",
            sys.executable,
            "-c",
            "import json, os; print(json.dumps(dict(os.environ)))",
        ]
        return subprocess.run(command, env=env, capture_output=True, text=True)

    def test_default_profile_uses_clean_environment(self):
        self.profile("personal", 'PROFILE_SECRET="present"\n')
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        env = json.loads(result.stdout)
        self.assertEqual(env["AI_PROFILE"], "personal")
        self.assertEqual(env["PROFILE_SECRET"], "present")
        self.assertEqual(env["HERDR_WORKSPACE_ID"], "workspace-test")
        self.assertEqual(env["AI_PROFILES_DIR"], str(self.profiles))
        self.assertEqual(env["PI_CODING_AGENT_DIR"], str(self.home / ".pi" / "agent"))
        self.assertNotIn("AMBIENT_SECRET", env)

    def test_default_profile_root_ignores_profile_xdg_data_home(self):
        self.profiles = self.home / ".local" / "share" / "ai" / "profiles"
        self.profile("personal", "PROFILE_SECRET=present\n")
        result = self.invoke(
            profiles_dir=False,
            extra_env={"XDG_DATA_HOME": str(self.root / "isolated-data")},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["PROFILE_SECRET"], "present")

    def test_profile_keys_include_every_profile_and_runtime_key(self):
        self.profile("personal", "PERSONAL_TOKEN=value\n")
        self.profile("job-one", "JOB_TOKEN=value\n")
        result = subprocess.run(
            [str(SCRIPT), "--profile-keys"],
            env={
                "AI_PROFILES_DIR": str(self.profiles),
                "HOME": str(self.home),
                "PATH": os.environ["PATH"],
            },
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        keys = set(result.stdout.splitlines())
        self.assertTrue({"PERSONAL_TOKEN", "JOB_TOKEN", "CODEX_HOME"} <= keys)

    def test_profile_keys_survive_malformed_other_profile(self):
        self.profile("personal", "PERSONAL_TOKEN=value\n")
        self.profile("broken", 'BROKEN_TOKEN="unterminated\n')
        result = subprocess.run(
            [str(SCRIPT), "--profile-keys"],
            env={
                "AI_PROFILES_DIR": str(self.profiles),
                "HOME": str(self.home),
                "PATH": os.environ["PATH"],
            },
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue({"PERSONAL_TOKEN", "BROKEN_TOKEN"} <= set(result.stdout.splitlines()))

    def test_named_profile_gets_private_homes(self):
        self.profile("job-one", "JOB_TOKEN=value\n")
        result = self.invoke("job-one")
        self.assertEqual(result.returncode, 0, result.stderr)
        env = json.loads(result.stdout)
        directory = self.profiles / "job-one"
        self.assertEqual(env["AI_PROFILE"], "job-one")
        self.assertEqual(env["CODEX_HOME"], str(directory / "codex"))
        self.assertEqual(env["CLAUDE_CONFIG_DIR"], str(directory / "claude"))
        self.assertEqual(env["OPENCODE_CONFIG_DIR"], str(directory / "opencode"))
        self.assertEqual(env["PI_CODING_AGENT_DIR"], str(directory / "pi"))
        self.assertEqual(env["XDG_DATA_HOME"], str(directory / "xdg-data"))
        self.assertTrue((directory / "codex").is_dir())
        self.assertTrue((directory / "pi").is_dir())
        self.assertTrue((directory / "pi" / "extensions").is_dir())

    def test_workspace_profile_overrides_default(self):
        self.profile("job-two", "JOB_TOKEN=value\n")
        result = self.invoke(extra_env={"AI_PROFILE": "job-two"})
        self.assertEqual(result.returncode, 0, result.stderr)
        env = json.loads(result.stdout)
        self.assertEqual(env["AI_PROFILE"], "job-two")

    def test_named_profile_reuses_nonsecret_pi_config(self):
        shared = self.home / ".pi" / "agent"
        (shared / "extensions").mkdir(parents=True)
        (shared / "AGENTS.md").write_text("instructions")
        (shared / "APPEND_SYSTEM.md").write_text("contract")
        (shared / "settings.defaults.json").write_text('{"defaultModel":"model"}')
        (shared / "extensions" / "herdr-agent-state.ts").write_text("extension")
        (shared / "extensions" / "workspace-sandbox.ts").write_text("sandbox")
        self.profile("job-three", "JOB_TOKEN=value\n")
        result = self.invoke("job-three")
        self.assertEqual(result.returncode, 0, result.stderr)
        target = self.profiles / "job-three" / "pi"
        self.assertTrue((target / "AGENTS.md").is_symlink())
        self.assertTrue((target / "APPEND_SYSTEM.md").is_symlink())
        self.assertFalse((target / "settings.json").is_symlink())
        self.assertEqual(
            (target / "settings.json").read_text(),
            '{"defaultModel":"model"}',
        )
        self.assertEqual((target / "settings.json").stat().st_mode & 0o777, 0o600)
        self.assertTrue((target / "extensions" / "herdr-agent-state.ts").is_symlink())
        self.assertTrue((target / "extensions" / "workspace-sandbox.ts").is_symlink())

    def test_rejects_public_profile_file(self):
        self.profile("personal", "TOKEN=value\n", 0o644)
        result = self.invoke()
        self.assertEqual(result.returncode, 2)
        self.assertIn("must be private", result.stderr)

    def test_rejects_public_profile_directory(self):
        self.profile("personal", "TOKEN=value\n")
        (self.profiles / "personal").chmod(0o755)
        result = self.invoke()
        self.assertEqual(result.returncode, 2)
        self.assertIn("directory must be private", result.stderr)

    def test_rejects_runtime_override(self):
        self.profile("personal", "PATH=/tmp\n")
        result = self.invoke()
        self.assertEqual(result.returncode, 2)
        self.assertIn("cannot override runtime key", result.stderr)

    def test_rejects_non_file_profile(self):
        path = self.profiles / "personal" / "env"
        path.mkdir(parents=True)
        path.parent.chmod(0o700)
        result = self.invoke()
        self.assertEqual(result.returncode, 2)
        self.assertIn("not a regular file", result.stderr)

    def test_rejects_invalid_profile(self):
        self.profile("personal", "TOKEN=value\n")
        result = self.invoke("../job")
        self.assertEqual(result.returncode, 2)
        self.assertIn("invalid profile", result.stderr)

    def test_help(self):
        result = subprocess.run([str(SCRIPT), "--help"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("usage: ai-run", result.stdout)


if __name__ == "__main__":
    unittest.main()
