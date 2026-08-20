import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/helpers/rich_text_document.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/recipe_review.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/rich_text_editor.dart';
import 'package:kitchenowl/widgets/rich_text_preview.dart';

class RecipeReviews extends StatelessWidget {
  final Recipe recipe;
  final bool canReview;
  final VoidCallback onChanged;

  const RecipeReviews({
    super.key,
    required this.recipe,
    required this.canReview,
    required this.onChanged,
  });

  Future<void> _editReview(BuildContext context) async {
    final result = await showDialog<_RecipeReviewResult>(
      context: context,
      builder: (context) => _RecipeReviewDialog(
        rating: recipe.myRating ?? 0,
        review: recipe.myReview,
      ),
    );
    if (result == null || !context.mounted) return;

    if (result.delete) {
      final confirmed = await askForConfirmation(
        context: context,
        title: Text(AppLocalizations.of(context)!.recipeReviewDelete),
        content: Text(
          AppLocalizations.of(context)!.recipeReviewDeleteConfirmation,
        ),
      );
      if (!confirmed || !context.mounted) return;
      final updated = await ApiService.getInstance().deleteRecipeReview(recipe);
      if (updated != null && context.mounted) onChanged();
      return;
    }

    final updated = await ApiService.getInstance().saveRecipeReview(
      recipe,
      rating: result.rating!,
      review: result.review,
    );
    if (updated != null && context.mounted) {
      onChanged();
      showSnackbar(
        context: context,
        content: Text(AppLocalizations.of(context)!.recipeReviewSaved),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.recipeReviews,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (canReview)
                  IconButton(
                    tooltip: localizations.recipeRate,
                    onPressed: () => _editReview(context),
                    icon: Icon(
                      recipe.myRating == null
                          ? Icons.star_border_rounded
                          : Icons.edit_rounded,
                    ),
                  ),
              ],
            ),
            if (recipe.ratingCount > 0)
              Row(
                children: [
                  _RecipeStars(value: recipe.ratingAverage),
                  const SizedBox(width: 8),
                  Text(
                    '${recipe.ratingAverage.toStringAsFixed(1)} · ${localizations.recipeRatingCount(recipe.ratingCount)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            else if (!canReview)
              Text(localizations.recipeReviewEmpty),
            if (canReview) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _editReview(context),
                icon: Icon(
                  recipe.myRating == null
                      ? Icons.star_border_rounded
                      : Icons.edit_rounded,
                ),
                label: Text(
                  recipe.myRating == null
                      ? localizations.recipeRate
                      : '${localizations.recipeRating}: ${recipe.myRating}/5',
                ),
              ),
            ],
            if (recipe.reviews.isNotEmpty) ...[
              const Divider(height: 28),
              ...recipe.reviews.map((review) => _ReviewTile(review: review)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final RecipeReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final name = review.user?.name.isNotEmpty == true
        ? review.user!.name
        : review.user?.username ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              _RecipeStars(value: review.rating.toDouble(), size: 18),
            ],
          ),
          if (review.review.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            RichTextDocument.isRichText(review.review)
                ? RichTextPreview(value: review.review)
                : Text(review.review),
          ],
        ],
      ),
    );
  }
}

class _RecipeStars extends StatelessWidget {
  final double value;
  final double size;

  const _RecipeStars({required this.value, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final position = index + 1;
        final icon = value >= position
            ? Icons.star_rounded
            : value >= position - 0.5
                ? Icons.star_half_rounded
                : Icons.star_border_rounded;
        return Icon(
          icon,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        );
      }),
    );
  }
}

class _RecipeReviewResult {
  final int? rating;
  final String review;
  final bool delete;

  const _RecipeReviewResult({
    this.rating,
    this.review = '',
    this.delete = false,
  });
}

class _RecipeReviewDialog extends StatefulWidget {
  final int rating;
  final String review;

  const _RecipeReviewDialog({required this.rating, required this.review});

  @override
  State<_RecipeReviewDialog> createState() => _RecipeReviewDialogState();
}

class _RecipeReviewDialogState extends State<_RecipeReviewDialog> {
  late int rating = widget.rating;
  late String review = widget.review;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(localizations.recipeRate),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  tooltip: '$star/5',
                  onPressed: () => setState(() => rating = star),
                  icon: Icon(
                    star <= rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 34,
                  ),
                );
              }),
            ),
            RichTextEditor(
              value: review,
              editorHeight: 180,
              placeholder: localizations.recipeReviewHint,
              onChanged: (value) => review = value,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.rating > 0)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const _RecipeReviewResult(delete: true),
            ),
            child: Text(localizations.delete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        FilledButton(
          onPressed: rating == 0
              ? null
              : () => Navigator.of(context).pop(
                    _RecipeReviewResult(
                      rating: rating,
                      review: review,
                    ),
                  ),
          child: Text(localizations.save),
        ),
      ],
    );
  }
}
