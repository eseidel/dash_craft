import 'dart:math';
import 'package:meta/meta.dart';

import 'items.dart';
import 'game.dart';

// Can Recipes unify with gather/hunt actions?
// Would need to have a "which human can do this"
// as well as a "which tool is needed to do this" (e.g. gather, axe, etc.)

// These are effectively classes of tools?
// enum MinionAction {
//   gather, // hand
//   lumberjack, // axe
//   hunt, // weapon
//   fish, // fishing rod
//   explore, // torch
// }

// These are skill classes, rather than classes of tools?
// enum MeTools {
//   mealPrep,
//   pickaxe,
//   shovel,
//   none,
// }

class ItemCount {
  final Item item;
  final int count;
  ItemCount(this.item, this.count);
}

List<Item> flatten(Map<Item, int> counts) {
  var items = <Item>[];
  for (var item in counts.keys) {
    var count = counts[item]!;
    for (var i = 0; i < count; i++) {
      items.add(item);
    }
  }
  return items;
}

@immutable
class Recipe {
  final Map<Item, int> inputs;
  // Tool
  // Skill required
  final Skill skill;
  final int skillLevel;
  // Percentage chance for a given output (e.g. eggs)
  final Map<Item, int> outputs;
  final bool failureGivesGoop;
  const Recipe({
    required this.inputs,
    required this.outputs,
    required this.skill,
    required this.skillLevel,
    this.failureGivesGoop = false,
  });

  Iterable<ItemCount> get inputCounts =>
      inputs.entries.map((e) => ItemCount(e.key, e.value));
  Iterable<ItemCount> get outputCounts =>
      outputs.entries.map((e) => ItemCount(e.key, e.value));

  int inputCount(Item item) => inputs[item] ?? 0;
  int outputCount(Item item) => outputs[item] ?? 0;

  List<Item> get inputAsList => flatten(inputs);
  // Does not respect percentage-based outputs.
  List<Item> get outputAsList => flatten(outputs);
}

var recipes = const [
  Recipe(
    inputs: {banana: 1},
    outputs: {peeledBanana: 1},
    failureGivesGoop: true,
    skill: Skill.gather,
    skillLevel: 0,
  ),
];

// FIXME: This function can't cover all items as designed.
// It does not cover minion actions (which are a source of items).
// e.g. gathering, hunting, exporing, etc.
Iterable<Recipe> recipesWithOutput(Item output) sync* {
  for (var recipe in recipes) {
    if (recipe.outputs.keys.contains(output)) {
      yield recipe;
    }
  }
}

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
class RecipeLookup {
  final Recipe recipe;
  final int count;
  const RecipeLookup(this.recipe, this.count);
}

// class Cookbook {
//   int inputsMatchMultipler(CraftingInputs inputs, Recipe recipe) {
//     var inputTypes = inputs.sortedTypes;
//     var recipeTypes = recipe.sortedInputTypes;
//     if (!const IterableEquality().equals(inputTypes, recipeTypes)) {
//       return 0;
//     }
//     int multiplier = 0;
//     for (int i = 0; i < recipeTypes.length; i++) {
//       int inputCount = inputs.countOf(recipeTypes[i]);
//       int recipeCount = recipe.countOf(recipeTypes.first);
//       int remainder = inputCount % recipeCount;
//       if (remainder != 0) return 0;
//       int newMultipler = inputCount ~/ recipeCount;
//       if (multiplier == 0) {
//         multiplier = newMultipler;
//       } else if (multiplier != newMultipler) {
//         return 0;
//       }
//     }
//     return multiplier;
//   }

//   RecipeLookup? findRecipe(CraftingInputs inputs) {
//     // Some recipes use stacks.
//     for (var recipe in recipes) {
//       int multipler = inputsMatchMultipler(inputs, recipe);
//       if (multipler > 0) {
//         return RecipeLookup(recipe, multipler);
//       }
//     }
//     return null;
//   }
// }

// Shouldn't be mutable.
class CraftingInputs {
  late List<ItemStack> _stacks;

  CraftingInputs({List<ItemStack>? stacks})
      : assert(stacks == null || stacks.length <= 3) {
    _stacks = stacks ?? [];
  }
  ItemStack? get first => _stacks.isNotEmpty ? _stacks.first : null;
  ItemStack? get second => _stacks.length > 1 ? _stacks[1] : null;
  ItemStack? get third => _stacks.length > 2 ? _stacks[2] : null;

  ItemStack? stackWithMatchingType(Item type) {
    for (var stack in _stacks) {
      if (stack.type == type) {
        return stack;
      }
    }
    return null;
  }

  int countOf(Item type) => stackWithMatchingType(type)?.count ?? 0;

  List<Item> get sortedTypes {
    var types = _stacks.map((stack) => stack.type).toList();
    types.sort();
    return types;
  }

  void clear() {
    _stacks = [];
  }

  bool addOneFrom(ItemStack toAdd) {
    assert(toAdd.count > 0);
    // Does this durability match?  Should it?
    var existingStack = stackWithMatchingType(toAdd.type);
    if (existingStack != null) {
      var haveSpace = existingStack.haveSpaceFor(toAdd);
      if (!haveSpace) {
        print('Item already on table, but not enough space!');
        return false;
      }
      existingStack.takeFrom(toAdd, limit: 1);
      return true;
    }
    if (_stacks.length >= 3) {
      print('crafting table already has 3 stacks!');
      return false;
    }
    _stacks.add(toAdd.takeOneAsNewStack());
    return true;
  }
}

class ItemStack {
  final Item type;
  int count;
  ItemStack({required this.type, this.count = 1});

  // int get energy => type.energy * count;
  int get spaceLeft => type.stackSize - count;

  void takeFrom(ItemStack from, {int limit = 100}) {
    if (from.type != type) {
      throw ArgumentError('Can\'t add non-matching item type.');
    }
    int maxCouldTake = min(from.count, spaceLeft);
    int taking = min(maxCouldTake, limit);
    count += taking;
    from.count -= taking;
  }

  bool haveSpaceFor(ItemStack from) {
    if (from.type != type) return false;
    return spaceLeft >= from.count;
  }

  // Not sure this is safe.
  ItemStack takeOneAsNewStack() {
    assert(count > 1);
    count -= 1;
    // Also copy durability!
    return ItemStack(type: type, count: 1);
  }
}

class ItemContainer {
  final int capacity;
  final List<ItemStack> _itemStacks = [];

  ItemContainer({required this.capacity});

  bool tryAdd(ItemStack toAdd) {
    // Go through each stack.
    // If we already have one of type add to that stack.
    for (var stack in _itemStacks) {
      if (stack.type == toAdd.type) {
        stack.takeFrom(toAdd);
        if (toAdd.count == 0) continue;
      }
    }
    // Items of equally reduced durability should be able to stack together.
    if (toAdd.count > 0 && _itemStacks.length < capacity) {
      _itemStacks.add(toAdd);
    }

    return toAdd.count == 0;
  }
}

// class Inventory extends ItemContainer {
//   Inventory() : super(capacity: 25);

//   ItemStack? stackAt(int index) {
//     if (index < _itemStacks.length) return _itemStacks[index];
//     return null;
//   }
// }

// This probably isn't necessary? this is just two doubles on the gamestate?
// class HumanState {
//   static const int maxEnergy = 100;
//   int energy = 7;

//   int get missingEnergy => maxEnergy - energy;
//   double get energyPercent => energy / maxEnergy;
// }
