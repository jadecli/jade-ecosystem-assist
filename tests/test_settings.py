# tests/test_settings.py
import pytest
from pathlib import Path
import os

def test_settings_module_imports():
    """Verify settings module can be imported."""
    from cli.settings import Settings, settings

    assert Settings is not None
    assert settings is not None

def test_settings_has_required_fields():
    """Verify settings has all required fields."""
    from cli.settings import settings

    required_attrs = [
        'environment',
        'is_ci',
        'home_dir',
        'projects_base',
        'jade_context_file',
        'ecosystem_assist_root',
        'submodules_path',
        'health_reports_dir',
        'context_token_budget',
    ]

    for attr in required_attrs:
        assert hasattr(settings, attr), f"Missing attribute: {attr}"

def test_settings_paths_are_pathlib():
    """Verify path settings are Path objects."""
    from cli.settings import settings

    path_attrs = [
        'home_dir',
        'projects_base',
        'jade_context_file',
        'ecosystem_assist_root',
        'submodules_path',
        'health_reports_dir',
    ]

    for attr in path_attrs:
        value = getattr(settings, attr)
        assert isinstance(value, Path), f"{attr} should be Path, got {type(value)}"

def test_settings_defaults():
    """Verify settings have sensible defaults."""
    from cli.settings import settings

    assert settings.environment == "development"
    assert settings.context_token_budget == 15000
    assert settings.ecosystem_assist_root.name == "jade-ecosystem-assist"
