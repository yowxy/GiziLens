"""Subscriptions and payments."""
from pathlib import Path
from alembic import op

revision = '0002'
down_revision = '0001'
branch_labels = None
depends_on = None


def _run_sql(direction: str) -> None:
    path = Path(__file__).parent / 'sql' / f'{revision}_{direction}.sql'
    # Bundled DDL has one semicolon at the end of each statement line.
    # No procedural SQL or quoted multiline SQL statements in these files.
    for statement in path.read_text(encoding='utf-8').split(';\n'):
        statement = statement.strip()
        if statement:
            op.execute(statement)


def upgrade() -> None:
    _run_sql('up')


def downgrade() -> None:
    _run_sql('down')
