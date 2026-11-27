"""Apply the GiziLens PostgreSQL migrations (Alembic) and optional seeds.

Usage (from backend/):
    python scripts/init_db.py
    python scripts/init_db.py --no-seed          # schema only
    python scripts/init_db.py --database-url "postgresql://user:pass@host:5432/db"

DATABASE_URL is read from the environment or backend/.env. The SQLAlchemy-style
``postgresql+psycopg://`` prefix is converted to a plain libpq DSN for seeding.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
MIGRATIONS_DIR = BASE_DIR / "app" / "database" / "migrations"
SEED_FILES = (
    MIGRATIONS_DIR / "seeds" / "001_draft_plans.sql",
    MIGRATIONS_DIR / "seeds" / "002_draft_akg_targets.sql",
)


def read_env() -> dict[str, str]:
    env: dict[str, str] = {}
    env_path = BASE_DIR / ".env"
    if env_path.exists():
        for line in env_path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            env[key.strip()] = value.strip()
    env.update({k: v for k, v in os.environ.items() if k == "DATABASE_URL"})
    return env


def libpq_dsn(url: str) -> str:
    for prefix in ("postgresql+psycopg://", "postgresql+asyncpg://", "postgresql+psycopg2://"):
        if url.startswith(prefix):
            return "postgresql://" + url[len(prefix):]
    return url


def run_migrations(database_url: str) -> None:
    print("-> alembic upgrade head")
    env = {**os.environ, "DATABASE_URL": database_url}
    subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=MIGRATIONS_DIR,
        env=env,
        check=True,
    )


def run_seeds(database_url: str) -> None:
    import psycopg

    with psycopg.connect(libpq_dsn(database_url)) as conn:
        for path in SEED_FILES:
            if not path.exists():
                continue
            print(f"-> seed {path.name}")
            with conn.cursor() as cur:
                cur.execute(path.read_text(encoding="utf-8"))
        conn.commit()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database-url", default=None)
    parser.add_argument("--no-seed", action="store_true")
    args = parser.parse_args()

    database_url = args.database_url or read_env().get("DATABASE_URL", "").strip()
    if not database_url:
        sys.exit("DATABASE_URL belum disetel di backend/.env")

    run_migrations(database_url)
    if not args.no_seed:
        run_seeds(database_url)
    print("Selesai. Jalankan `alembic current` di folder migrations untuk memeriksa revisi.")


if __name__ == "__main__":
    main()
