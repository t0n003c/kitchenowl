import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/helpers/recipe_shuffle_deck.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/index_bar.dart';
import 'package:kitchenowl/widgets/choice_scroll.dart';
import 'package:kitchenowl/widgets/recipe_card.dart';
import 'package:kitchenowl/widgets/recipe_item.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final TextEditingController searchController = TextEditingController();
  late final IndexScrollController scrollController;
  final headerKey = GlobalKey();

  double getRowHeight() {
    if (!mounted) return 1;
    if (!BlocProvider.of<RecipeListCubit>(context).state.gridView) return 56;
    return ((headerKey.currentContext!.size!.width - 16 - 32) / getRowCount()) /
        0.67;
  }

  double getHeaderHeight() {
    return headerKey.currentContext!.size!.height;
  }

  int getRowCount() {
    if (!mounted) return 1;
    if (!BlocProvider.of<RecipeListCubit>(context).state.gridView) return 1;
    // header width - list padding
    return ((headerKey.currentContext!.size!.width - 16 - 32) / 328).ceil();
  }

  @override
  void initState() {
    super.initState();
    searchController.text = BlocProvider.of<RecipeListCubit>(context).query;
    scrollController = IndexScrollController(
      getRowHeight: getRowHeight,
      getHeaderHeight: getHeaderHeight,
      getItemRowCount: getRowCount,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<RecipeListCubit>(context);

    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: BlocListener<RecipeListCubit, RecipeListState>(
                bloc: cubit,
                listener: (context, state) {
                  if (state is! SearchRecipeListState) {
                    if (searchController.text.isNotEmpty) {
                      searchController.clear();
                    }
                  }
                },
                child: SearchTextField(
                  controller: searchController,
                  clearOnSubmit: false,
                  onSearch: (s) => cubit.search(s),
                  textInputAction: TextInputAction.search,
                  suffix: !App.isOffline
                      ? IconButton(
                          onPressed: () => context.go(
                            "/household/${cubit.household.id}/recipes/discover",
                            extra: cubit.household,
                          ),
                          tooltip: AppLocalizations.of(context)!.discover,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<RecipeListCubit, RecipeListState>(
              bloc: cubit,
              builder: (context, state) {
                Widget header = Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: PopupMenuButton<RecipeListViewMode>(
                    onSelected: (view) => cubit.setView(view),
                    itemBuilder: (context) => [
                      for (final view in RecipeListViewMode.values)
                        PopupMenuItem(
                          value: view,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_viewIcon(view)),
                              const SizedBox(width: 12),
                              Text(_viewLabel(context, view)),
                            ],
                          ),
                        ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_viewLabel(context, state.viewMode)),
                        const SizedBox(width: 4),
                        Icon(_viewIcon(state.viewMode)),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                );
                if (state is! ListRecipeListState ||
                    state.tags.isEmpty ||
                    state is SearchRecipeListState) {
                  header = Align(
                    key: headerKey,
                    alignment: Alignment.topRight,
                    child: header,
                  );
                } else {
                  header = Align(
                    key: headerKey,
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: LeftRightWrap(
                        crossAxisSpacing: 6,
                        left: ChoiceScroll(
                            children: state.tags
                                .sorted((a, b) =>
                                    (state is FilteredListRecipeListState)
                                        ? state.selectedTags
                                            .contains(a)
                                            .hashCode
                                            .compareTo(state.selectedTags
                                                .contains(b)
                                                .hashCode)
                                        : 0)
                                .map((tag) {
                          return Padding(
                            key: ValueKey(tag.id),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(
                                tag.name,
                                style: TextStyle(
                                  color: (state
                                              is FilteredListRecipeListState) &&
                                          state.selectedTags.contains(tag)
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                ),
                              ),
                              selected:
                                  (state is FilteredListRecipeListState) &&
                                      state.selectedTags.contains(tag),
                              selectedColor:
                                  Theme.of(context).colorScheme.secondary,
                              onSelected: (bool selected) =>
                                  cubit.tagSelected(tag, selected),
                            ),
                          );
                        }).toList()),
                        right: header,
                      ),
                    ),
                  );
                }

                if (state is! ListRecipeListState) {
                  return Column(
                    children: [
                      header,
                      const Padding(
                        padding: EdgeInsets.only(left: 28, right: 12),
                        child: ShimmerCard(
                            trailing: Icon(Icons.arrow_right_rounded)),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 28, right: 12),
                        child: ShimmerCard(
                            trailing: Icon(Icons.arrow_right_rounded)),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 28, right: 12),
                        child: ShimmerCard(
                            trailing: Icon(Icons.arrow_right_rounded)),
                      ),
                    ],
                  );
                }
                final recipes = state.recipes;

                if (recipes.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      header,
                      const Spacer(),
                      const Icon(Icons.no_food_rounded),
                      const SizedBox(height: 16),
                      Text(state is SearchRecipeListState ||
                              state is FilteredListRecipeListState
                          ? AppLocalizations.of(context)!.recipeEmptySearch
                          : AppLocalizations.of(context)!.recipeEmpty),
                      const Spacer(),
                    ],
                  );
                }

                if (state.shuffleView) {
                  return Column(
                    children: [
                      header,
                      Expanded(
                        child: ShuffleRecipeView(
                          key: ValueKey(
                            recipes.map((recipe) => recipe.id).join(','),
                          ),
                          recipes: recipes,
                          onUpdated: cubit.refresh,
                        ),
                      ),
                    ],
                  );
                }

                return RefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: Stack(
                    children: [
                      CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverToBoxAdapter(child: header),
                          SliverPadding(
                            padding: EdgeInsets.only(
                                left: state is SearchRecipeListState ? 16 : 32,
                                right: 16),
                            sliver: state.listView
                                ? SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, i) => RecipeItemWidget(
                                        recipe: recipes[i],
                                        onUpdated: cubit.refresh,
                                      ),
                                      childCount: recipes.length,
                                    ),
                                  )
                                : SliverGrid.builder(
                                    itemCount: recipes.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 328,
                                      childAspectRatio: 0.67,
                                    ),
                                    itemBuilder: (context, i) => RecipeCard(
                                      key: Key(recipes[i].name),
                                      recipe: recipes[i],
                                      onUpdated: cubit.refresh,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (state is! SearchRecipeListState)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IndexBar(
                            controller: scrollController,
                            names: recipes.map((r) => r.name).toList(),
                            indexHintDecoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(0xFF),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                  blurRadius: 6,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            indexHintTextStyle: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


String _viewLabel(BuildContext context, RecipeListViewMode view) {
  return switch (view) {
    RecipeListViewMode.alphabetical =>
      AppLocalizations.of(context)!.sortingAlphabetical,
    RecipeListViewMode.grid => AppLocalizations.of(context)!.grid,
    RecipeListViewMode.shuffle => AppLocalizations.of(context)!.swipeShuffle,
  };
}

IconData _viewIcon(RecipeListViewMode view) {
  return switch (view) {
    RecipeListViewMode.alphabetical => Icons.view_agenda_rounded,
    RecipeListViewMode.grid => Icons.grid_view_rounded,
    RecipeListViewMode.shuffle => Icons.shuffle_rounded,
  };
}

class ShuffleRecipeView extends StatefulWidget {
  final List<Recipe> recipes;
  final Future<void> Function()? onUpdated;

  const ShuffleRecipeView({
    super.key,
    required this.recipes,
    this.onUpdated,
  });

  @override
  State<ShuffleRecipeView> createState() => _ShuffleRecipeViewState();
}

class _ShuffleRecipeViewState extends State<ShuffleRecipeView> {
  final RecipeShuffleDeck _deck = RecipeShuffleDeck();
  int _cycle = 0;

  @override
  void initState() {
    super.initState();
    _deck.setRecipes(widget.recipes);
  }

  @override
  void didUpdateWidget(covariant ShuffleRecipeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.recipes, widget.recipes)) {
      _deck.setRecipes(widget.recipes);
      _cycle++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _deck.current;
    if (recipe == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Dismissible(
        key: ValueKey('shuffle-${_cycle}-${recipe.id}'),
        direction: DismissDirection.horizontal,
        background: _swipeBackground(
          context,
          Alignment.centerLeft,
          Icons.arrow_forward_rounded,
        ),
        secondaryBackground: _swipeBackground(
          context,
          Alignment.centerRight,
          Icons.arrow_back_rounded,
        ),
        onDismissed: (_) {
          setState(() {
            _deck.advance();
            _cycle++;
          });
        },
        child: SizedBox.expand(
          child: RecipeCard(
            recipe: recipe,
            width: double.infinity,
            onUpdated: () {
              widget.onUpdated?.call();
            },
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground(
    BuildContext context,
    Alignment alignment,
    IconData icon,
  ) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }
}
