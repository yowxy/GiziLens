"""Track successful AI detection independently of saved inspections."""

from alembic import op

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        CREATE TABLE detection_usage (
            id uuid PRIMARY KEY,
            firebase_uid varchar(128) NOT NULL,
            started_at timestamptz NOT NULL DEFAULT now(),
            status varchar(20) NOT NULL
                CHECK (status IN (
                    'RESERVED', 'USED', 'RELEASED'
                )),
            reservation_expires_at timestamptz,
            CHECK (
                status <> 'RESERVED'
                OR reservation_expires_at IS NOT NULL
            )
        )
    """)

    op.execute("""
        CREATE INDEX ix_detection_usage_uid_time
        ON detection_usage (
            firebase_uid,
            started_at,
            status
        )
    """)

    op.execute("""
        INSERT INTO detection_usage (
            id,
            firebase_uid,
            started_at,
            status
        )
        SELECT
            id,
            firebase_uid,
            created_at,
            'USED'
        FROM scans
        WHERE status = 'SUCCESS'
        AND firebase_uid <> 'anonymous'
    """)


def downgrade():
    op.drop_table('detection_usage')
