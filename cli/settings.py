# cli/settings.py
# ---
# entity_id: module-settings
# entity_name: Centralized Settings
# entity_type_id: module
# entity_path: cli/settings.py
# entity_language: python
# entity_state: active
# entity_exports: [Settings, settings]
# ---

from pathlib import Path
from typing import Optional
import os


class Settings:
    """Centralized configuration for jade-ecosystem-assist."""

    def __init__(self):
        # Environment Detection
        self.environment: str = os.getenv("ENVIRONMENT", "development")
        self.is_ci: bool = os.getenv("CI", "false").lower() == "true"

        # Paths
        self.home_dir: Path = Path.home()

        self.projects_base: Path = Path(
            os.getenv("PROJECTS_BASE", str(self.home_dir / "projects"))
        )

        self.jade_context_file: Path = Path(
            os.getenv("JADE_CONTEXT_FILE", str(self.home_dir / ".jade" / "context.md"))
        )

        self.ecosystem_assist_root: Path = Path(__file__).parent.parent

        self.submodules_path: Path = Path(
            os.getenv("SUBMODULES_PATH", str(self.ecosystem_assist_root / "modules"))
        )

        self.health_reports_dir: Path = Path(
            os.getenv(
                "HEALTH_REPORTS_DIR",
                str(self.ecosystem_assist_root / "docs" / "health-reports"),
            )
        )

        # Context Generation
        self.context_token_budget: int = int(
            os.getenv("CONTEXT_TOKEN_BUDGET", "15000")
        )

        # GitHub Integration
        self.github_token: Optional[str] = os.getenv("GITHUB_TOKEN")


# Singleton instance
settings = Settings()
