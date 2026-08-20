"""allow rich-text recipe reviews

Revision ID: a3f4e8d2c901
Revises: 7b6f4d3e2a10
Create Date: 2026-08-20 00:00:00.000000

"""

from alembic import op
import sqlalchemy as sa


revision = "a3f4e8d2c901"
down_revision = "7b6f4d3e2a10"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("recipe_review", schema=None) as batch_op:
        batch_op.alter_column(
            "review",
            existing_type=sa.String(length=2000),
            type_=sa.Text(),
            existing_nullable=False,
        )


def downgrade():
    with op.batch_alter_table("recipe_review", schema=None) as batch_op:
        batch_op.alter_column(
            "review",
            existing_type=sa.Text(),
            type_=sa.String(length=2000),
            existing_nullable=False,
        )
