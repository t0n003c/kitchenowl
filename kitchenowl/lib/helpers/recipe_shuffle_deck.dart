import 'dart:math';

import 'package:kitchenowl/models/recipe.dart';

class RecipeShuffleDeck {
  final Random _random;
  List<Recipe> _recipes = const [];
  List<Recipe> _remaining = const [];

  RecipeShuffleDeck({Random? random}) : _random = random ?? Random();

  Recipe? get current => _remaining.isEmpty ? null : _remaining.first;

  void setRecipes(Iterable<Recipe> recipes) {
    _recipes = List<Recipe>.from(recipes);
    _reshuffle();
  }

  void advance() {
    if (_remaining.isEmpty) return;

    _remaining = List<Recipe>.from(_remaining)..removeAt(0);
    if (_remaining.isEmpty && _recipes.isNotEmpty) {
      _reshuffle();
    }
  }

  void _reshuffle() {
    _remaining = List<Recipe>.from(_recipes)..shuffle(_random);
  }
}
