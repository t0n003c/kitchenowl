from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING, Any, cast

from sqlalchemy import CheckConstraint, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped

from app import db

Model = db.Model
if TYPE_CHECKING:
    from app.helpers.db_model_base import DbModelBase
    from app.models import Recipe, User

    Model = DbModelBase


class RecipeReview(Model):
    __tablename__ = "recipe_review"
    __table_args__ = (
        UniqueConstraint("recipe_id", "user_id", name="uq_recipe_review_recipe_user"),
        CheckConstraint("rating >= 1 AND rating <= 5", name="ck_recipe_review_rating"),
    )

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    recipe_id: Mapped[int] = db.Column(
        db.Integer,
        ForeignKey("recipe.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[int] = db.Column(
        db.Integer,
        ForeignKey("user.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    rating: Mapped[int] = db.Column(db.Integer, nullable=False)
    review: Mapped[str] = db.Column(db.Text(), nullable=False, default="")

    recipe: Mapped["Recipe"] = cast(
        Mapped["Recipe"],
        db.relationship("Recipe", back_populates="reviews", uselist=False),
    )
    user: Mapped["User"] = cast(
        Mapped["User"],
        db.relationship("User", back_populates="recipe_reviews", uselist=False),
    )

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
        skip = list(skip_columns or [])
        skip.extend(["recipe_id", "user_id", "created_at", "updated_at"])
        res = super().obj_to_dict(skip, include_columns)
        res["user"] = self.user.obj_to_dict() if self.user else None
        res["created_at"] = self._timestamp(self.created_at)
        res["updated_at"] = self._timestamp(self.updated_at)
        return res

    @staticmethod
    def _timestamp(value: datetime | None) -> int | None:
        return round(value.timestamp() * 1000) if value else None
