import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:tuple/tuple.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool showHousehold;
  final void Function()? onUpdated;
  final void Function()? onPressed;
  final Future<void> Function()? onLongPressed;
  final Future<void> Function()? onAddToDate;
  final double? width;
  final double? imageAspectRatio;
  final TextStyle? titleStyle;
  final String? attribution;
  final int imageFlex;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onUpdated,
    this.onPressed,
    this.onLongPressed,
    this.onAddToDate,
    this.showHousehold = false,
    this.width,
    this.imageAspectRatio,
    this.titleStyle,
    this.attribution,
    this.imageFlex = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ??
          getValueForScreenType(
            context: context,
            mobile: 250,
            tablet: 275,
            desktop: 275,
          ),
      child: Card(
        child: InkWell(
          onTap: onPressed ??
              () async {
                String query = "?showHousehold=${showHousehold}";
                final household =
                    context.read<HouseholdCubit?>()?.state.household;
                if (household == null) {
                  debugPrint(
                      "RecipeCard onTap called without a Household context");
                  final lastHousehold =
                      await PreferenceStorage.getInstance().readInt(
                    key: 'lastHouseholdId',
                  );
                  if (lastHousehold == null) {
                    context.push<UpdateEnum>(
                      "/recipe/${recipe.id}${query}",
                      extra: recipe,
                    );
                  } else {
                    final res = await context.push<UpdateEnum>(
                      "/household/${lastHousehold}/recipes/details/${recipe.id}${query}",
                      extra: Tuple2<Household, Recipe>(
                          Household(id: lastHousehold), recipe),
                    );
                    _handleUpdate(res);
                  }
                } else {
                  final res = await context.push<UpdateEnum>(
                    "/household/${household.id}/recipes/details/${recipe.id}${query}",
                    extra: Tuple2<Household, Recipe>(household, recipe),
                  );
                  _handleUpdate(res);
                }
              },
          onLongPress: onLongPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageAspectRatio != null)
                AspectRatio(
                  aspectRatio: imageAspectRatio!,
                  child: _buildImage(context),
                )
              else
                Expanded(
                  flex: imageFlex,
                  child: _buildImage(context),
                ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (recipe.tags.isNotEmpty)
                        ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment(.7, 0),
                              end: Alignment.centerRight,
                              colors: [Colors.black, Colors.transparent],
                            ).createShader(
                              Rect.fromLTRB(0, 0, rect.width, rect.height),
                            );
                          },
                          blendMode: BlendMode.dstIn,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              children: recipe.tags
                                  .map((e) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        child: Chip(
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          label: Text(e.name),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        recipe.name,
                        maxLines: getValueForScreenType(
                          context: context,
                          mobile: 2,
                          tablet: 2,
                          desktop: 2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: titleStyle ??
                            Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (recipe.ratingCount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => Icon(
                                recipe.ratingAverage >= index + 1
                                    ? Icons.star_rounded
                                    : recipe.ratingAverage >= index + 0.5
                                        ? Icons.star_half_rounded
                                        : Icons.star_border_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipe.ratingAverage.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!
                                    .recipeRatingCount(recipe.ratingCount),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (onLongPressed == null &&
                          (recipe.prepTime > 0 || recipe.cookTime > 0)) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            if (recipe.prepTime > 0)
                              _RecipeMeta(
                                icon: Icons.restaurant_rounded,
                                label:
                                    '${AppLocalizations.of(context)!.preparationTime}: ${recipe.prepTime} ${AppLocalizations.of(context)!.minutesAbbrev}',
                              ),
                            if (recipe.cookTime > 0)
                              _RecipeMeta(
                                icon: Icons.local_fire_department_rounded,
                                label:
                                    '${AppLocalizations.of(context)!.cookingTime}: ${recipe.cookTime} ${AppLocalizations.of(context)!.minutesAbbrev}',
                              ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      if ((showHousehold && recipe.household != null) ||
                          _sourceLabel(recipe) != null ||
                          attribution != null)
                        Row(
                          children: [
                            if (_sourceLabel(recipe) != null)
                              Icon(
                                isValidUrl(recipe.source)
                                    ? Icons.link_rounded
                                    : Icons.person_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            else if (recipe.household != null)
                              HouseholdCircleAvatar(
                                household: recipe.household!,
                                radius: 15,
                              )
                            else
                              Icon(
                                Icons.person_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.recipeFrom(
                                  _sourceLabel(recipe) ??
                                      recipe.household?.name ??
                                      attribution!,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            if (_sourceLabel(recipe) == null &&
                                (recipe.household?.verified ?? false))
                              Icon(
                                Icons.verified_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      if (onLongPressed != null) const Divider(),
                      if (onLongPressed != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onAddToDate != null)
                              LoadingElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  padding: EdgeInsets.zero,
                                ).copyWith(
                                  elevation: ButtonStyleButton.allOrNull(0.0),
                                  iconColor: WidgetStatePropertyAll(
                                      Theme.of(context).colorScheme.onPrimary),
                                ),
                                onPressed: onAddToDate,
                                child: const Icon(Icons.calendar_month_rounded),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: LoadingElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ).copyWith(
                                  elevation: ButtonStyleButton.allOrNull(0.0),
                                ),
                                onPressed: onLongPressed,
                                child: LayoutBuilder(builder:
                                    (BuildContext context,
                                        BoxConstraints size) {
                                  final TextPainter painter = TextPainter(
                                    maxLines: 1,
                                    textAlign: TextAlign.left,
                                    textDirection: TextDirection.ltr,
                                    text: TextSpan(
                                      text: AppLocalizations.of(context)!
                                          .addRecipeToPlannerShort,
                                    ),
                                  );

                                  painter.layout(maxWidth: size.maxWidth);

                                  return Text(
                                    painter.didExceedMaxLines
                                        ? AppLocalizations.of(context)!.add
                                        : AppLocalizations.of(context)!
                                            .addRecipeToPlannerShort,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (recipe.image?.isNotEmpty ?? false)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final devicePixelRatio =
                    MediaQuery.devicePixelRatioOf(context);
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                final height = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : width;
                final maxWidth = (width * devicePixelRatio * 1.15)
                    .round()
                    .clamp(512, 1536)
                    .toInt();
                final maxHeight = (height * devicePixelRatio * 1.15)
                    .round()
                    .clamp(512, 2048)
                    .toInt();

                return FadeInImage(
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholder: recipe.imageHash != null
                      ? BlurHashImage(recipe.imageHash!)
                      : MemoryImage(kTransparentImage) as ImageProvider,
                  image: getImageProvider(
                    context,
                    recipe.image!,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                  ),
                );
              },
            ),
          ),
        if (recipe.image?.isEmpty ?? true)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
            child: Icon(
              Icons.fastfood_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        if (recipe.time > 0)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.topLeft,
              child: Chip(
                avatar: Icon(Icons.timer_rounded),
                label: Text(
                  "${recipe.time} min",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String? _sourceLabel(Recipe recipe) {
    final source = recipe.source.trim();
    if (source.isEmpty || source.startsWith('kitchenowl://')) return null;

    final uri = Uri.tryParse(source);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host.replaceFirst(RegExp(r'^www\.'), '');
    }

    return source;
  }

  void _handleUpdate(UpdateEnum? res) {
    if (onUpdated != null &&
        (res == UpdateEnum.updated || res == UpdateEnum.deleted)) {
      onUpdated!();
    }
  }
}

class _RecipeMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RecipeMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
