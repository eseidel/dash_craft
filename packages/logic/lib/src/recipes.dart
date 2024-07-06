import 'package:collection/collection.dart';
import 'package:logic/game.dart';
import 'package:logic/rules.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

// Can Recipes unify with gather/hunt actions?
// Would need to have a "which human can do this"
// as well as a "which tool is needed to do this" (e.g. gather, axe, etc.)

class ItemCount {
  ItemCount(this.item, this.count);
  final Item item;
  final int count;
}

List<Item> flatten(Map<Item, int> counts) {
  final items = <Item>[];
  for (final item in counts.keys) {
    final count = counts[item]!;
    for (var i = 0; i < count; i++) {
      items.add(item);
    }
  }
  return items;
}

@immutable
class Recipe {
  const Recipe({
    required this.name,
    required this.inputs,
    required this.outputs,
    required this.tool,
    required this.skill,
    required this.skillRequired,
    required this.failureOutputs,
  });

  factory Recipe.fromYaml(YamlMap map, ItemSet items) {
    final inputs = (map['in'] as Map)
        .map((key, value) => MapEntry(items[key as String], value as int));
    final outputs = (map['out'] as Map)
        .map((key, value) => MapEntry(items[key as String], value as int));
    return Recipe(
      name: map['name'] as String? ?? outputs.keys.first.name,
      inputs: inputs,
      outputs: outputs,
      tool: ToolType.fromString(map['tool'] as String),
      skill: Skill.fromString(map['skill'] as String),
      skillRequired: map['min_skill'] as int? ?? 0,
      failureOutputs: ((map['fail'] as List?) ?? [])
          .cast<String>()
          .map((name) => items[name])
          .toList(),
    );
  }

  final String name;
  final Map<Item, int> inputs;
  final ToolType tool;
  // Skill required
  final Skill skill;
  final int skillRequired;
  // Percentage chance for a given output (e.g. eggs)
  final Map<Item, int> outputs;
  final List<Item> failureOutputs;

  Iterable<ItemCount> get inputCounts =>
      inputs.entries.map((e) => ItemCount(e.key, e.value));
  Iterable<ItemCount> get outputCounts =>
      outputs.entries.map((e) => ItemCount(e.key, e.value));

  int inputCount(Item item) => inputs[item] ?? 0;
  int outputCount(Item item) => outputs[item] ?? 0;

  List<Item> get inputAsList => flatten(inputs);
  // Does not respect percentage-based outputs.
  List<Item> get outputAsList => flatten(outputs);

  Set<Item> get uniqueItems => inputs.keys.toSet();

  @override
  String toString() {
    return 'Recipe($name)';
  }
}

class RecipeSet {
  RecipeSet._(this._byName);

  factory RecipeSet.fromYaml(YamlMap yaml, ItemSet items) {
    final byName = <String, Recipe>{};
    for (final recipeYaml in yaml['recipes'] as YamlList) {
      final recipe = Recipe.fromYaml(recipeYaml as YamlMap, items);
      byName[recipe.name] = recipe;
    }
    return RecipeSet._(byName);
  }

  final Map<String, Recipe> _byName;

  Iterable<Recipe> get all => _byName.values;

  Recipe operator [](String name) {
    return _byName[name]!;
  }
}

// List<Recipe> recipes = const [
//   Recipe.food(
//     outputs: {peeledBanana: 1},
//     inputs: {banana: 1},
//     skillRequired: 0,
//     tool: ToolType.hand,
//   ),
//   Recipe.food(
//     outputs: {peeledOrange: 1},
//     inputs: {orange: 1},
//     skillRequired: 0,
//     tool: ToolType.hand,
//   ),
//   Recipe.food(
//     outputs: {walnutKernel: 1},
//     inputs: {walnut: 1},
//     tool: ToolType.stone,
//     skillRequired: 0,
//   ),
//   Recipe.food(
//     outputs: {slicedBanana: 1},
//     inputs: {peeledBanana: 1},
//     tool: ToolType.sharpStone,
//     skillRequired: 0,
//   ),
//   Recipe.food(
//     outputs: {peanutKernel: 1},
//     inputs: {peanut: 1},
//     tool: ToolType.hand,
//     skillRequired: 5,
//   ),
//   Recipe.food(
//     outputs: {openedCoconut: 2},
//     inputs: {coconut: 1},
//     tool: ToolType.stone,
//     skillRequired: 10,
//   ),
//   Recipe.food(
//     outputs: {rawCoconut: 1},
//     inputs: {openedCoconut: 1},
//     tool: ToolType.sharpStone,
//     skillRequired: 15,
//   ),
//   Recipe.food(
//     outputs: {mixedBerries: 1},
//     inputs: {redberry: 1, blueberry: 1},
//     tool: ToolType.hand,
//     skillRequired: 15,
//   ),
//   Recipe.food(
//     outputs: {chestnutKernel: 1},
//     inputs: {chestnut: 1},
//     tool: ToolType.stone,
//     skillRequired: 15,
//   ),
//   Recipe.food(
//     outputs: {blueBerryMash: 1},
//     inputs: {blueberry: 2, coconutShell: 1},
//     tool: ToolType.stone,
//     skillRequired: 15,
//   ),
//   Recipe.food(
//     outputs: {redBerryMash: 1},
//     inputs: {redberry: 2, coconutShell: 1},
//     tool: ToolType.stone,
//     skillRequired: 15,
//   ),
//   Recipe.food(
//     outputs: {mixedBerryMash: 1},
//     inputs: {mixedBerries: 2, coconutShell: 1},
//     tool: ToolType.stone,
//     skillRequired: 20,
//   ),
//   Recipe.food(
//     outputs: {bananaMash: 1},
//     inputs: {banana: 2, coconutShell: 1},
//     tool: ToolType.stone,
//     skillRequired: 25,
//   ),
//   Recipe.food(
//     outputs: {slicedOrange: 1},
//     inputs: {orange: 1},
//     tool: ToolType.sharpStone,
//     skillRequired: 25,
//   ),
//   Recipe.food(
//     outputs: {slicedTomato: 1},
//     inputs: {tomato: 1},
//     tool: ToolType.sharpStone,
//     skillRequired: 30,
//   ),
//   Recipe.food(
//     outputs: {slicedCarrot: 1},
//     inputs: {carrot: 1},
//     tool: ToolType.sharpStone,
//     skillRequired: 30,
//   ),
//   Recipe.food(
//     outputs: {cutLettuce: 1},
//     inputs: {lettuce: 1},
//     tool: ToolType.sharpStone,
//     skillRequired: 30,
//   ),
//   Recipe.tool(
//     outputs: {sharpStone: 1},
//     inputs: {stone: 1},
//     tool: ToolType.stone,
//     skillRequired: 0,
//   ),
// ];

// Peeled Banana	Banana			Hand	0	1	3
// Peeled Orange	Orange			Hand	0	1	3
// Walnut Kernel	Walnut			Stone	0	1	4
// Sliced Banana	Peeled Banana			Sharp Stone	0	1	8
// Peanut Kernel	Peanut			Hand	5	1	3
// 2 Opened Coconut	Coconut			Stone	10	1	2
// Raw Coconut	Opened Coconut			Sharp Stone	15	1	8
// Mixed Berries	Blue Berry	Red Berry		Hand	15	1	5
// Chestnut Kernel	Chestnut			Stone	15	1	4
// Blue Berry Mash	2 Blue Berry	Coconut Shell		Stone	15	1	8
// Red Berry Mash	2 Red Berry	Coconut Shell		Stone	15	1	8
// Mixed Berry Mash	2 Mixed Berries	Coconut Shell		Stone	20	1	15
// Banana Mash	2 Peeled Banana	Coconut Shell		Stone	25	1	12
// Sliced Orange	Orange			Sharp Stone	25	1	6
// Sliced Tomato	Tomato			Sharp Stone	30	1	8
// Sliced Carrot	Carrot			Sharp Stone	30	1	8
// Cut Lettuce	Lettuce			Sharp Stone	30	1	7
// Pot Full of Water	Cooking Pot	Water Bowl x3		Hand	30
// Sliced Eggplant	Eggplant			Sharp Stone	35		9
// Sliced Potato	Potato			Sharp Stone	35		10
// Carrot Salad	Sliced Carrot	Cut Lettuce	Coconut Shell	Hand	35	1	20
// Tomato Salad	Sliced Tomato	Cut Lettuce	Coconut Shell	Hand	35	1	20
// Walnut Salad	Walnut Kernel	Cut Lettuce	Coconut Shell	Hand	40		16
// Mashed Potatoes	2 Potatoes	Coconut Shell		Stone	40		16
// Mashed Root	2 Root	Coconut Shell		Stone	40		8
// Bone Marrow	Bone			Stone Axe	45	1	7
// Sliced Apple	Apple			Primitive Knife	50		10
// Orange Juice	2 Peeled orange	Coconut Shell		Stone	55		12
// Sliced Mushroom	Mushroom			Primitive Knife	55		12
// Raw Kebab	Peeled Stick	Sliced Tomato	Red Meat	Hand	60		27

@immutable
class RecipeMatch {
  const RecipeMatch(this.recipe, this.count);
  final Recipe recipe;
  final int count;
}

@immutable
class Cookbook {
  const Cookbook(this.recipes);

  final RecipeSet recipes;

  RecipeMatch? matchesRecipe(CraftingBench bench, Recipe recipe) {
    if (bench.toolType != recipe.tool) return null;
    // TODO(eseidel): Also check tool durability?

    final inputs = bench.inputs;
    final inputTypes = inputs.uniqueItems.toList()..sort();
    final recipeTypes = recipe.uniqueItems.toList()..sort();
    if (!const IterableEquality<Item>().equals(inputTypes, recipeTypes)) {
      return null;
    }
    var multiplier = 0;
    for (var i = 0; i < recipeTypes.length; i++) {
      final inputCount = inputs.countOf(recipeTypes[i]);
      final recipeCount = recipe.inputCount(recipeTypes.first);
      final remainder = inputCount % recipeCount;
      if (remainder != 0) return null;
      final newMultipler = inputCount ~/ recipeCount;
      if (multiplier == 0) {
        multiplier = newMultipler;
      } else if (multiplier != newMultipler) {
        return null;
      }
    }
    return RecipeMatch(recipe, multiplier);
  }

  RecipeMatch? findRecipe(CraftingBench bench) {
    // Some recipes use stacks.
    for (final recipe in recipes.all) {
      final match = matchesRecipe(bench, recipe);
      if (match != null) {
        return match;
      }
    }
    return null;
  }
}

// Where do we store the tool?  The tool needs a durability, so it's an
// ItemStack (of size 1?).  But it's not in the same container as the rest
// of the inputs.

@immutable
class InputsContainer extends StackContainer {
  InputsContainer({required super.stacks}) : super(size: 3);
  const InputsContainer.empty() : super.empty(size: 3);

  // TODO(eseidel): Preserve stack order.
  InputsContainer copyWith({List<Item>? removed, List<Item>? added}) {
    final counts = itemCountsAfterEdits(
      removed: removed ?? [],
      added: added ?? [],
    );
    final stacks = StackContainer.stacksFromCounts(counts);
    return InputsContainer(stacks: stacks);
  }
}

class ToolContainer extends StackContainer {
  ToolContainer({required ItemStack tool}) : super(size: 1, stacks: [tool]);
  const ToolContainer.empty() : super.empty(size: 1);

  ToolType get toolType {
    final stack = this.stack;
    if (stack == null) return ToolType.hand;
    return stack.type.tool!;
  }

  ItemStack? get stack => this[0];

  ToolContainer copyWith({Item? removed, Item? added}) {
    final counts = itemCountsAfterEdits(
      removed: removed == null ? [] : [removed],
      added: added == null ? [] : [added],
    );
    final stacks = StackContainer.stacksFromCounts(counts);
    return ToolContainer(tool: stacks.first);
  }
}

@immutable
class CraftingBench {
  const CraftingBench({
    required this.inputs,
    this.tool = const ToolContainer.empty(),
  });
  @visibleForTesting
  CraftingBench.fromStacks(
    List<ItemStack> stacks, {
    this.tool = const ToolContainer.empty(),
  }) : inputs = InputsContainer(stacks: stacks);
  const CraftingBench.empty()
      : inputs = const InputsContainer.empty(),
        tool = const ToolContainer.empty();

  final InputsContainer inputs;
  final ToolContainer tool;

  ToolType get toolType => tool.toolType;

  ItemStack? get first => inputs[0];
  ItemStack? get second => inputs[1];
  ItemStack? get third => inputs[2];

  CraftingBench copyWith({InputsContainer? inputs, ToolContainer? tool}) {
    return CraftingBench(
      inputs: inputs ?? this.inputs,
      tool: tool ?? this.tool,
    );
  }
}

// Essentially an item instance.  Item is a type of item.
@immutable
class ItemStack {
  const ItemStack({required this.type, this.count = 1, this.durability})
      : assert(count > 0, 'count must be positive');
  final Item type;
  final int count;
  final int? durability;

  Item get item => type;

  static const int maxSize = 100;

  int? get energy {
    final energy = type.energy;
    if (energy == null) return null;
    return energy * count;
  }

  int get spaceLeft => maxSize - count;

  ItemStack copyWith({int? count, int? durability}) {
    return ItemStack(
      type: type,
      count: count ?? this.count,
      durability: durability ?? this.durability,
    );
  }

  bool haveSpaceFor(ItemStack from) {
    if (from.type != type) return false;
    return spaceLeft >= from.count;
  }

  List<Item> toList() => List.filled(count, type);
}

// class ItemContainer {
//   final int capacity;
//   final List<ItemStack> _itemStacks = [];

//   ItemContainer({required this.capacity});

//   bool tryAdd(ItemStack toAdd) {
//     // Go through each stack.
//     // If we already have one of type add to that stack.
//     for (var stack in _itemStacks) {
//       if (stack.type == toAdd.type) {
//         stack.takeFrom(toAdd);
//         if (toAdd.count == 0) continue;
//       }
//     }
//     // Items of equally reduced durability should be able to stack together.
//     if (toAdd.count > 0 && _itemStacks.length < capacity) {
//       _itemStacks.add(toAdd);
//     }

//     return toAdd.count == 0;
//   }
// }
