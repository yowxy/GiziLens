"""Engine / session management.

The engine is created lazily so the detection and payment endpoints keep
working even when PostgreSQL is not configured or temporarily unreachable.
"""
from __future__ import annotations

import time
from collections.abc import Iterator

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.config import get_settings

_engine: Engine | None = None
_session_factory: sessionmaker[Session] | None = None


def get_engine() -> Engine:
    global _engine
    if _engine is None:
        settings = get_settings()
        _engine = create_engine(
            settings.database_url,
            echo=settings.db_echo,
            pool_pre_ping=True,
            pool_size=settings.db_pool_size,
            max_overflow=5,
            connect_args={"connect_timeout": settings.db_connect_timeout},
            future=True,
        )
    return _engine


def get_session_factory() -> sessionmaker[Session]:
    global _session_factory
    if _session_factory is None:
        _session_factory = sessionmaker(
            bind=get_engine(), autoflush=False, expire_on_commit=False
        )
    return _session_factory


def get_db() -> Iterator[Session]:
    session = get_session_factory()()
    try:
        yield session
    finally:
        session.close()


def ping_db() -> tuple[bool, float | None]:
    """Return (reachable, latency_ms). Never raises."""
    try:
        started = time.perf_counter()
        with get_engine().connect() as connection:
            connection.execute(text("SELECT 1"))
        return True, round((time.perf_counter() - started) * 1000, 1)
    except Exception:
        return False, None
