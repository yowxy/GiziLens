"""Allow unlimited members for subscription plans."""

from alembic import op

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        ALTER TABLE plans
        DROP CONSTRAINT IF EXISTS plans_check
    """)

    op.create_check_constraint(
        "plans_check",
        "plans",
        """
        NOT is_active OR (
            scan_quota IS NOT NULL
            AND history_retention_days IS NOT NULL
        )
        """
    )


def downgrade():
    op.drop_constraint(
        "plans_check",
        "plans",
        type_="check"
    )

    op.create_check_constraint(
        "plans_check",
        "plans",
        """
        NOT is_active OR (
            scan_quota IS NOT NULL
            AND max_members IS NOT NULL
            AND history_retention_days IS NOT NULL
        )
        """
    )
