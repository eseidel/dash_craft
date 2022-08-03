import 'dart:math';
import 'package:collection/collection.dart';

// This should be yaml.

enum ItemClass {
  food,
  tool,
}

class ItemType {
  final String name;
  final ItemClass type;
  // Is everything allowed to stack?
  // Are things which can't stack just 1 offs?
  final int maxStackSize = 100;
  final int durability;
  final int energy;
  const ItemType.food({required this.name, required this.energy})
      : durability = 0,
        type = ItemClass.food;
  const ItemType.tool({required this.name, required this.durability})
      : energy = 0,
        type = ItemClass.tool;
}

const banana = ItemType.food(name: 'Banana', energy: 1);
const goop = ItemType.food(name: 'Goop', energy: -1);
const peeledBanana = ItemType.food(name: 'Peeled Banana', energy: 3);
const orange = ItemType.food(name: 'Orange', energy: 1);
const peeledOrange = ItemType.food(name: 'Peeled Orange', energy: 3);
const stone = ItemType.tool(name: 'Stone', durability: 5);
const walnut = ItemType.food(name: 'Walnut', energy: -2);
const cookedRedMeat = ItemType.food(name: 'Cooked Red Meat', energy: 13);

class Skills {
  double foodPrep = 0.0;
}

class Recipe {
  final List<ItemType> inputs;
  // Tool
  // Skill required
  final List<ItemType> outputs;
  final bool failureGivesGoop;
  const Recipe({
    required this.inputs,
    required this.outputs,
    this.failureGivesGoop = false,
  });

  List<ItemType> get sortedInputTypes => inputs;

  // Will need to be fixed for non-1 inputs.
  int countOf(ItemType type) {
    return inputs.contains(type) ? 1 : 0;
  }
}

var recipes = const [
  Recipe(inputs: [banana], outputs: [peeledBanana], failureGivesGoop: true),
];

class RecipeLookup {
  final Recipe recipe;
  final int count;
  RecipeLookup(this.recipe, this.count);
}

class Cookbook {
  int inputsMatchMultipler(CraftingInputs inputs, Recipe recipe) {
    var inputTypes = inputs.sortedTypes;
    var recipeTypes = recipe.sortedInputTypes;
    if (!const IterableEquality().equals(inputTypes, recipeTypes)) {
      return 0;
    }
    int multiplier = 0;
    for (int i = 0; i < recipeTypes.length; i++) {
      int inputCount = inputs.countOf(recipeTypes[i]);
      int recipeCount = recipe.countOf(recipeTypes.first);
      int remainder = inputCount % recipeCount;
      if (remainder != 0) return 0;
      int newMultipler = inputCount ~/ recipeCount;
      if (multiplier == 0) {
        multiplier = newMultipler;
      } else if (multiplier != newMultipler) {
        return 0;
      }
    }
    return multiplier;
  }

  RecipeLookup? findRecipe(CraftingInputs inputs) {
    // Some recipes use stacks.
    for (var recipe in recipes) {
      int multipler = inputsMatchMultipler(inputs, recipe);
      if (multipler > 0) {
        return RecipeLookup(recipe, multipler);
      }
    }
    return null;
  }
}

class CraftingInputs {
  late List<ItemStack> _stacks;

  CraftingInputs({List<ItemStack>? stacks})
      : assert(stacks == null || stacks.length <= 3) {
    _stacks = stacks ?? [];
  }
  ItemStack? get first => _stacks.isNotEmpty ? _stacks.first : null;
  ItemStack? get second => _stacks.length > 1 ? _stacks[1] : null;
  ItemStack? get third => _stacks.length > 2 ? _stacks[2] : null;

  ItemStack? stackWithMatchingType(ItemType type) {
    for (var stack in _stacks) {
      if (stack.type == type) {
        return stack;
      }
    }
    return null;
  }

  int countOf(ItemType type) => stackWithMatchingType(type)?.count ?? 0;

  List<ItemType> get sortedTypes {
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
  final ItemType type;
  int count;
  ItemStack({required this.type, this.count = 1});

  int get energy => type.energy * count;
  int get spaceLeft => type.maxStackSize - count;

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

class Inventory extends ItemContainer {
  Inventory() : super(capacity: 25);

  ItemStack? stackAt(int index) {
    if (index < _itemStacks.length) return _itemStacks[index];
    return null;
  }
}

class Human {
  static const int maxEnergy = 100;
  int energy = 7;

  int get missingEnergy => maxEnergy - energy;
  double get energyPercent => energy / maxEnergy;
}
