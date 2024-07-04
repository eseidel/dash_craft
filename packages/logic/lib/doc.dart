// Dawn of Crafting item names.

import 'dart:io';

import 'package:logic/items.dart';
import 'package:logic/recipes.dart';
import 'package:logic/tasks.dart';
import 'package:yaml/yaml.dart';

export 'package:logic/items.dart';
export 'package:logic/recipes.dart';
export 'package:logic/tasks.dart';

class Rules {
  const Rules({
    required this.items,
    required this.recipes,
    required this.tasks,
  });

  final ItemSet items;
  final RecipeSet recipes;
  final TaskSet tasks;

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

// Rules specific to Dawn of Crafting.
class DOC extends Rules {
  DOC({required super.items, required super.recipes, required super.tasks});

  factory DOC.load() {
    final items = ItemSet.fromYaml(_loadYaml('assets/items.yaml'));
    final recipes = RecipeSet.fromYaml(_loadYaml('assets/recipes.yaml'), items);
    final tasks = TaskSet.fromYaml(_loadYaml('assets/tasks.yaml'), items);
    return DOC(items: items, recipes: recipes, tasks: tasks);
  }

  static YamlMap _loadYaml(String path) {
    final contents = File(path).readAsStringSync();
    return loadYaml(contents) as YamlMap;
  }

  // These are mostly helpers for tests.
  static const String _peeledBananaName = 'Peeled Banana';
  Item get banana => items['Banana'];
  Item get peeledBanana => items[_peeledBananaName];
  Recipe get peeledBananaRecipe => recipes[_peeledBananaName];
  Item get goop => items['Goop'];
}
