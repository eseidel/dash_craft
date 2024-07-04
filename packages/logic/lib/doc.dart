// Dawn of Crafting item names.

import 'dart:io';

import 'package:logic/items.dart';
import 'package:logic/recipes.dart';
import 'package:yaml/yaml.dart';

export 'package:logic/items.dart';
export 'package:logic/recipes.dart';

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

  factory DOC.load({Uri? itemsUri, Uri? recipesUri}) {
    itemsUri ??= Uri.parse('assets/items.yaml');
    recipesUri ??= Uri.parse('assets/recipes.yaml');
    final items = ItemSet.fromYaml(_loadYaml(itemsUri));
    final recipes = RecipeSet.fromYaml(_loadYaml(recipesUri), items);
    return DOC(items: items, recipes: recipes);
  }

  static YamlMap _loadYaml(Uri uri) {
    final contents = File.fromUri(uri).readAsStringSync();
    return loadYaml(contents) as YamlMap;
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
