import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/helpers/recipe_shuffle_deck.dart';
import 'package:kitchenowl/models/recipe.dart';

void main() {
  test('shows every recipe once before reshuffling', () {
    final recipes = [
      const Recipe(id: 1, name: 'One'),
      const Recipe(id: 2, name: 'Two'),
      const Recipe(id: 3, name: 'Three'),
    ];
    final deck = RecipeShuffleDeck(random: Random(1))..setRecipes(recipes);
    final firstCycle = <int>[];

    for (var i = 0; i < recipes.length; i++) {
      firstCycle.add(deck.current!.id!);
      deck.advance();
    }

    expect(firstCycle.toSet(), hasLength(recipes.length));
    expect(firstCycle, containsAll(recipes.map((recipe) => recipe.id)));
    expect(deck.current, isNotNull);
  });

  test('empty deck stays empty', () {
    final deck = RecipeShuffleDeck(random: Random(1))..setRecipes(const []);

    expect(deck.current, isNull);
    deck.advance();
    expect(deck.current, isNull);
  });
}
