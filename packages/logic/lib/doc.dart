// Dawn of Crafting item names.

import 'package:dash_craft/items.dart';
import 'package:dash_craft/recipes.dart';

export 'package:dash_craft/items.dart';
export 'package:dash_craft/recipes.dart';

class Rules {
  const Rules({required this.items, required this.recipes});

  final ItemSet items;
  final RecipeSet recipes;

  // TODO(eseidel): This function can't cover all items as designed.
  // It does not cover minion actions (which are a source of items).
  // e.g. gathering, hunting, exporing, etc.
  Iterable<Recipe> recipesWithOutput(Item output) sync* {
    for (final recipe in recipes.all) {
      if (recipe.outputs.keys.contains(output)) {
        yield recipe;
      }
    }
  }
}

class DOC extends Rules {
  DOC({required super.items, required super.recipes})
      : stone = items['Stone'],
        banana = items['Banana'],
        peeledBanana = items['Peeled Banana'],
        goop = items['Goop'];

  factory DOC.load() {
    final items = ItemSet.fromYaml('assets/items.yaml');
    final recipes = RecipeSet.fromYaml('assets/recipes.yaml', items);
    return DOC(items: items, recipes: recipes);
  }

  final Item banana;
  final Item peeledBanana;
  final Item stone;
  final Item goop;

  List<Item> get gatherItems => [
        banana,
        stone,
      ];
}
