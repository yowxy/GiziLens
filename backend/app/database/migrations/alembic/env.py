"""Run hand-written PostgreSQL migrations with SQLAlchemy's asyncpg driver."""
import asyncio
import os
from pathlib import Path

from alembic import context
from sqlalchemy import pool
from sqlalchemy.ext.asyncio import create_async_engine
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parents[4] / '.env', override=False)


def database_url(offline: bool = False) -> str:
    url = os.getenv('DATABASE_URL', '').strip()
    if not url:
        if offline:
            return 'postgresql+asyncpg://localhost/gizilens'
        raise RuntimeError('DATABASE_URL belum disetel. Lihat .env.migrations.example.')
    for prefix in ('postgres://', 'postgresql://', 'postgresql+psycopg://'):
        if url.startswith(prefix):
            url = 'postgresql+asyncpg://' + url[len(prefix):]
            break
    if not url.startswith('postgresql+asyncpg://'):
        raise RuntimeError('Gunakan URL PostgreSQL dengan driver asyncpg.')
    return url


def run_migrations_offline() -> None:
    context.configure(
        url=database_url(offline=True),
        target_metadata=None,
        literal_binds=True,
        dialect_opts={'paramstyle': 'named'},
        transactional_ddl=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection) -> None:
    context.configure(connection=connection, target_metadata=None, transactional_ddl=True)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    engine = create_async_engine(database_url(), poolclass=pool.NullPool)
    try:
        async with engine.connect() as connection:
            await connection.run_sync(do_run_migrations)
    finally:
        await engine.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_async_migrations())
