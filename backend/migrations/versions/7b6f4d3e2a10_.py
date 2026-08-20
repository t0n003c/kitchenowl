"""add recipe ratings and reviews

Revision ID: 7b6f4d3e2a10
Revises: 0b10d67750be
Create Date: 2026-08-19 21:00:00.000000

"""

from alembic import op
import sqlalchemy as sa


revision = "7b6f4d3e2a10"
down_revision = "0b10d67750be"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "recipe_review",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("recipe_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("rating", sa.Integer(), nullable=False),
        sa.Column("review", sa.String(length=2000), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["recipe_id"], ["recipe.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "recipe_id", "user_id", name="uq_recipe_review_recipe_user"
        ),
        sa.CheckConstraint(
            "rating >= 1 AND rating <= 5", name="ck_recipe_review_rating"
        ),
    )
    with op.batch_alter_table("recipe_review", schema=None) as batch_op:
        batch_op.create_index("ix_recipe_review_recipe_id", ["recipe_id"], unique=False)
        batch_op.create_index("ix_recipe_review_user_id", ["user_id"], unique=False)


def downgrade():
    with op.batch_alter_table("recipe_review", schema=None) as batch_op:
        batch_op.drop_index("ix_recipe_review_user_id")
        batch_op.drop_index("ix_recipe_review_recipe_id")
    op.drop_table("recipe_review")
