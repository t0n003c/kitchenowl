import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/recipe_suggestions.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/household.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';

class RecipeDiscoverCubit extends Cubit<RecipeDiscoverState> {
  final Household? household;

  RecipeDiscoverCubit(this.household)
      : super(RecipeDiscoverLoadingState(household: household)) {
    refresh();
  }

  Future<void> refresh() async {
    emit(RecipeDiscoverLoadingState(household: household));
    Household? loadedHousehold = null;
    if (household != null) {
      loadedHousehold = await TransactionHandler.getInstance()
          .runTransaction(TransactionHouseholdGet(household: household!));
    }
    final suggestionsFuture = ApiService.getInstance()
        .discoverRecipes(loadedHousehold?.language);
    final householdRecipesFuture = loadedHousehold == null
        ? Future.value(<Recipe>[])
        : TransactionHandler.getInstance().runTransaction(
            TransactionRecipeGetRecipes(household: loadedHousehold),
          );
    final suggestions = await suggestionsFuture;
    final householdRecipes = await householdRecipesFuture;

    if (suggestions != null) {
      emit(RecipeDiscoverState(
        discover: suggestions,
        household: loadedHousehold,
        personalized: _personalize(householdRecipes),
      ));
    } else {
      emit(RecipeDiscoverErrorState(household: loadedHousehold));
    }
  }

  List<Recipe> _personalize(List<Recipe> recipes) {
    final personalized = recipes
        .where((recipe) => recipe.myRating != null || recipe.isPlanned)
        .toList();
    personalized.sort((a, b) {
      final aScore = (a.myRating ?? 0) * 100 + (a.isPlanned ? 20 : 0) +
          a.ratingAverage;
      final bScore = (b.myRating ?? 0) * 100 + (b.isPlanned ? 20 : 0) +
          b.ratingAverage;
      return bScore.compareTo(aScore);
    });
    return personalized.take(12).toList();
  }
}

class RecipeDiscoverState extends Equatable {
  final RecipeDiscover discover;
  final Household? household;
  final List<Recipe> personalized;

  RecipeDiscoverState({
    this.household,
    required this.discover,
    this.personalized = const [],
  });

  @override
  List<Object?> get props => [discover, household, personalized];
}

class RecipeDiscoverLoadingState extends RecipeDiscoverState {
  RecipeDiscoverLoadingState({super.household})
      : super(discover: const RecipeDiscover());
}

class RecipeDiscoverErrorState extends RecipeDiscoverState {
  RecipeDiscoverErrorState({super.household})
      : super(discover: const RecipeDiscover());
}
