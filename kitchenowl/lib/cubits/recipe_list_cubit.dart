import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';
import 'package:kitchenowl/services/transactions/tag.dart';

enum RecipeListViewMode { alphabetical, grid, shuffle }

class RecipeListCubit extends Cubit<RecipeListState> {
  final Household household;
  List<Recipe> recipeList = [];
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;

  RecipeListCubit(this.household) : super(const LoadingRecipeListState()) {
    PreferenceStorage.getInstance().readBool(key: 'recipeListView').then((i) {
      if (i != null) {
        setView(
          i ? RecipeListViewMode.alphabetical : RecipeListViewMode.grid,
          savePreference: false,
        );
      }
    });
    _initialLoad();
  }

  String get query => (state is SearchRecipeListState)
      ? (state as SearchRecipeListState).query
      : "";

  Future<void> search(String query) {
    return refresh(query);
  }

  void tagSelected(Tag tag, bool selected) {
    if (state is FilteredListRecipeListState) {
      final _state = state as FilteredListRecipeListState;
      final selectedTags = Set<Tag>.from(_state.selectedTags);
      if (selected) {
        selectedTags.add(tag);
      } else {
        selectedTags.removeWhere((e) => e.id == tag.id);
      }
      if (selectedTags.isEmpty) {
        emit(
          ListRecipeListState(
            recipes: _state.allRecipes,
            tags: _state.tags,
            viewMode: state.viewMode,
          ),
        );
      } else {
        emit(_state.copyWith(
          viewMode: state.viewMode,
          selectedTags: selectedTags,
          recipes: _getFilteredRecipesCopy(
            _state.allRecipes,
            selectedTags,
          ),
        ));
      }
    } else if (selected) {
      emit(FilteredListRecipeListState.fromState(
        state as ListRecipeListState,
        tag,
      ));
    }
  }

  Future<void> refresh([String? query]) {
    final state = this.state;
    if (state is SearchRecipeListState) {
      query = query ?? state.query;
    }
    if (_refreshThread == null || query != _refreshCurrentQuery) {
      _refreshCurrentQuery = query;
      _refreshThread = _refresh(query);
    }

    return _refreshThread!;
  }

  Future<void> _initialLoad() async {
    final tags = TransactionHandler.getInstance().runTransaction(
      TransactionTagGetAll(household: household),
      forceOffline: true,
    );
    recipeList = await TransactionHandler.getInstance().runTransaction(
      TransactionRecipeGetRecipes(household: household),
      forceOffline: true,
    );

    if (state is LoadingRecipeListState && recipeList.isNotEmpty) {
      emit(ListRecipeListState(
        recipes: recipeList,
        tags: await tags,
        viewMode: state.viewMode,
      ));
    }
  }

  Future<void> _refresh([String? query, bool runOffline = false]) async {
    late ListRecipeListState _state;
    if (state is ListRecipeListState &&
        state is! SearchRecipeListState &&
        state is! FilteredListRecipeListState &&
        (state as ListRecipeListState).recipes.isEmpty) {
      emit(LoadingRecipeListState(viewMode: state.viewMode));
    }

    if (query != null && query.isNotEmpty) {
      final tags = TransactionHandler.getInstance()
          .runTransaction(TransactionTagGetAll(household: household));
      final recipes = TransactionHandler.getInstance()
          .runTransaction(TransactionRecipeSearchRecipes(
        household: household,
        query: query,
      ));

      _state = SearchRecipeListState(
        query: query,
        recipes: await recipes,
        tags: await tags,
        viewMode: state.viewMode,
      );
    } else {
      if (!runOffline && state is SearchRecipeListState) _refresh(query, true);
      final tags = TransactionHandler.getInstance().runTransaction(
        TransactionTagGetAll(household: household),
        forceOffline: runOffline,
      );
      recipeList = await TransactionHandler.getInstance().runTransaction(
        TransactionRecipeGetRecipes(household: household),
        forceOffline: runOffline,
      );
      Set<Tag> filter = const {};
      if (state is FilteredListRecipeListState && (query == null)) {
        filter = (state as FilteredListRecipeListState).selectedTags;
      }
      _state = filter.isNotEmpty
          ? FilteredListRecipeListState(
              recipes: _getFilteredRecipesCopy(recipeList, filter),
              tags: await tags,
              selectedTags: filter,
              allRecipes: recipeList,
              viewMode: state.viewMode,
            )
          : ListRecipeListState(
              recipes: recipeList,
              tags: await tags,
              viewMode: state.viewMode,
            );
    }
    if (query == _refreshCurrentQuery) {
      emit(_state);
      _refreshThread = null;
    }
  }

  List<Recipe> _getFilteredRecipesCopy(
    List<Recipe> allRecipes,
    Set<Tag> filter,
  ) =>
      List<Recipe>.from(
        allRecipes.where((e) => e.tags.containsAll(filter)),
      );

  void toggleView([bool savePreference = true]) {
    final nextView = switch (state.viewMode) {
      RecipeListViewMode.alphabetical => RecipeListViewMode.grid,
      RecipeListViewMode.grid => RecipeListViewMode.alphabetical,
      RecipeListViewMode.shuffle => RecipeListViewMode.alphabetical,
    };
    setView(nextView, savePreference: savePreference);
  }

  void setView(
    RecipeListViewMode viewMode, {
    bool savePreference = true,
  }) {
    if (savePreference && viewMode != RecipeListViewMode.shuffle) {
      PreferenceStorage.getInstance().writeBool(
        key: 'recipeListView',
        value: viewMode == RecipeListViewMode.alphabetical,
      );
    }
    emit(state.copyWith(viewMode: viewMode));
  }
}

abstract class RecipeListState extends Equatable {
  final RecipeListViewMode viewMode;
  const RecipeListState({this.viewMode = RecipeListViewMode.alphabetical});

  bool get listView => viewMode == RecipeListViewMode.alphabetical;
  bool get gridView => viewMode == RecipeListViewMode.grid;
  bool get shuffleView => viewMode == RecipeListViewMode.shuffle;

  @override
  List<Object?> get props => [viewMode];

  RecipeListState copyWith({RecipeListViewMode? viewMode});
}

class LoadingRecipeListState extends RecipeListState {
  const LoadingRecipeListState({super.viewMode});

  @override
  RecipeListState copyWith({RecipeListViewMode? viewMode}) {
    return LoadingRecipeListState(viewMode: viewMode ?? this.viewMode);
  }
}

class ListRecipeListState extends RecipeListState {
  final List<Recipe> recipes;
  final Set<Tag> tags;

  const ListRecipeListState({
    this.recipes = const [],
    this.tags = const {},
    super.viewMode,
  });

  @override
  List<Object?> get props => super.props + <Object?>[tags] + recipes;

  @override
  RecipeListState copyWith({RecipeListViewMode? viewMode}) {
    return ListRecipeListState(
      viewMode: viewMode ?? this.viewMode,
      recipes: recipes,
      tags: tags,
    );
  }
}

class FilteredListRecipeListState extends ListRecipeListState {
  final Set<Tag> selectedTags;
  final List<Recipe> allRecipes;

  const FilteredListRecipeListState({
    this.selectedTags = const {},
    this.allRecipes = const [],
    super.recipes = const [],
    super.tags = const {},
    super.viewMode,
  });

  factory FilteredListRecipeListState.fromState(
    ListRecipeListState state,
    Tag selectedTag,
  ) =>
      FilteredListRecipeListState(
        recipes: List<Recipe>.from(
          state.recipes.where((e) => e.tags.contains(selectedTag)),
        ),
        allRecipes: state.recipes,
        tags: state.tags,
        selectedTags: {selectedTag},
        viewMode: state.viewMode,
      );

  @override
  FilteredListRecipeListState copyWith({
    RecipeListViewMode? viewMode,
    List<Recipe>? recipes,
    Set<Tag>? tags,
    Set<Tag>? selectedTags,
  }) =>
      FilteredListRecipeListState(
        viewMode: viewMode ?? this.viewMode,
        recipes: recipes ?? this.recipes,
        tags: tags ?? this.tags,
        selectedTags: selectedTags ?? this.selectedTags,
        allRecipes: allRecipes,
      );

  @override
  List<Object?> get props => super.props + [selectedTags];
}

class SearchRecipeListState extends ListRecipeListState {
  final String query;

  const SearchRecipeListState({
    required this.query,
    super.recipes = const [],
    super.tags = const {},
    super.viewMode,
  });

  @override
  List<Object?> get props => super.props + [query];

  @override
  RecipeListState copyWith({RecipeListViewMode? viewMode}) {
    return SearchRecipeListState(
      viewMode: viewMode ?? this.viewMode,
      query: query,
      recipes: recipes,
      tags: tags,
    );
  }
}
