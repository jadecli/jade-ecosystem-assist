# tests/test_session_hook.py
import pytest
from pathlib import Path
import subprocess

def test_session_hook_exists():
    """Verify session hook file exists and is executable."""
    hook_file = Path(".claude/hooks/session-start.sh")
    assert hook_file.exists(), "Session hook file missing"
    assert hook_file.stat().st_mode & 0o111, "Session hook not executable"

def test_session_hook_runs():
    """Verify session hook can execute without errors."""
    hook_file = Path(".claude/hooks/session-start.sh")

    result = subprocess.run(
        [str(hook_file)],
        capture_output=True,
        text=True,
    )

    # Hook should exit 0 (success or skip)
    assert result.returncode == 0, f"Hook failed: {result.stderr}"

def test_session_hook_sources_settings():
    """Verify hook loads settings correctly."""
    hook_file = Path(".claude/hooks/session-start.sh")
    content = hook_file.read_text()

    # Should source load-settings.sh or use Python settings
    assert "cli.settings import settings" in content, "Hook doesn't use settings"
