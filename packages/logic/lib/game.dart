import 'dart:math';

import 'package:collection/collection.dart';
import 'package:logic/logger.dart';
import 'package:logic/rules.dart';
import 'package:logic/src/action.dart';
import 'package:meta/meta.dart';

enum Skill {
  // My Skills
  mealPreparing('Meal Preparing'),
  toolCrafting('Tool Crafting'),
  woodWorking('Wood Working'),
  skinning('Skinning'),
  cooking('Cooking'),
  tailoring('Tailoring'),
  pottery('Pottery'),
  construction('Construction'),
  painting('Painting'),
  // Minion Skills
  gathering('Gathering'),
  lumberjack('Lumberjack'),
  hunting('Hunting'),
  fishing('Fishing'),
  treasureHunting('Treasure Hunting'),
  communication('Communication');

  const Skill(this.displayName);

  final String displayName;

  static List<Skill> get mySkills =>
      Skill.values.where((s) => s.index < Skill.gathering.index).toList();

  static List<Skill> get minionSkills =>
      Skill.values.where((s) => s.index >= Skill.gathering.index).toList();

  static Skill fromString(String name) {
    final skill = Skill.values.firstWhereOrNull((e) => e.name == name);
    if (skill == null) {
      throw ArgumentError('Unknown skill: $name');
    }
    return skill;
  }
}

@immutable
class Skills {
  const Skills([this.skillToLevel = const {}]);
  final Map<Skill, double> skillToLevel;

  double operator [](Skill skill) => skillToLevel[skill] ?? 0.0;
  void operator []=(Skill skill, double level) => skillToLevel[skill] = level;

  Skills copyWith(Map<Skill, double> skills) {
    final newSkills = Map<Skill, double>.from(skillToLevel)..addAll(skills);
    return Skills(newSkills);
  }

  Skills operator +(Skills other) {
    final newSkills = Map<Skill, double>.from(skillToLevel);
    for (final skill in other.skillToLevel.keys) {
      final level = newSkills[skill] ?? 0.0;
      newSkills[skill] = level + other[skill];
    }
    return Skills(newSkills);
  }

  static const double skillCap = 100;

  double get totalValue => Skill.values.fold(0, (a, b) => a + this[b]);
  double get totalPercent => totalValue / (Skill.values.length * skillCap);

  @override
  String toString() {
    return 'Skills(${Skill.values.map((s) => '${s.name}: ${this[s].toStringAsFixed(1)}').join(', ')})';
  }
}

@immutable
class StackContainer {
  StackContainer({required List<ItemStack> stacks, required this.size})
      : _stacks = stacks {
    if (stacks.length > size) {
      throw ArgumentError('Too many stacks: $stacks');
    }
  }

  @visibleForTesting
  StackContainer.fromCounts({
    required Map<Item, int> itemCounts,
    required this.size,
  }) : _stacks = stacksFromCounts(itemCounts) {
    if (_stacks.length > size) {
      throw ArgumentError('Too many stacks: $_stacks');
    }
  }

  StackContainer.fromJson(Map<String, dynamic> json, ItemSet items)
      : this(
          stacks: stacksFromJson(json['stacks'] as List, items),
          size: json['size'] as int,
        );

  const StackContainer.empty({required this.size})
      : _stacks = const <ItemStack>[];

  static List<ItemStack> stacksFromJson(
    List<dynamic> json,
    ItemSet items,
  ) {
    return json
        .map((s) => ItemStack.fromJson(s as Map<String, dynamic>, items))
        .toList();
  }

  static List<ItemStack> stacksFromCounts(Map<Item, int> itemCounts) {
    final stacks = <ItemStack>[];
    for (final entry in itemCounts.entries) {
      final item = entry.key;
      var left = entry.value;
      const stackSize = ItemStack.maxSize;
      while (left > 0) {
        final count = left > stackSize ? stackSize : left;
        stacks.add(ItemStack(type: item, count: count));
        left -= count;
      }
    }
    return stacks;
  }

  List<ItemStack> get stacks => List<ItemStack>.unmodifiable(_stacks);

  final List<ItemStack> _stacks;
  final int size;

  bool get isEmpty => _stacks.isEmpty;

  ItemStack? operator [](int index) {
    if (index >= _stacks.length) {
      return null;
    }
    return _stacks[index];
  }

  // Hack for now.
  bool hasRoomFor(ItemStack stack) => true;

  Map<Item, int> get itemCounts {
    final itemToCount = <Item, int>{};
    for (final stack in _stacks) {
      itemToCount[stack.item] = (itemToCount[stack.item] ?? 0) + stack.count;
    }
    return Map<Item, int>.unmodifiable(itemToCount);
  }

  static Map<Item, int> toItemCounts(List<Item> items) {
    final itemToCount = <Item, int>{};
    for (final item in items) {
      itemToCount[item] = (itemToCount[item] ?? 0) + 1;
    }
    return Map<Item, int>.unmodifiable(itemToCount);
  }

  Map<Item, int> itemCountsAfterEdits({
    required List<Item> removed,
    required List<Item> added,
  }) {
    final newItemCounts = Map<Item, int>.from(itemCounts);
    if (removed.isNotEmpty) {
      for (final toRemove in removed) {
        assert(newItemCounts[toRemove] != null, 'Item $toRemove not in $this');
        assert(newItemCounts[toRemove]! > 0, 'Item $toRemove not in $this');
        final newCount = (newItemCounts[toRemove] ?? 0) - 1;
        // Important to remove the key if the count is 0 otherwise
        // uniqueItems will be wrong.
        if (newCount == 0) {
          newItemCounts.remove(toRemove);
        } else {
          newItemCounts[toRemove] = newCount;
        }
      }
    }
    if (added.isNotEmpty) {
      for (final toAdd in added) {
        newItemCounts[toAdd] = (newItemCounts[toAdd] ?? 0) + 1;
      }
    }
    return Map<Item, int>.unmodifiable(newItemCounts);
  }

  Iterable<Item> get uniqueItems => _stacks.map((stack) => stack.item).toSet();

  List<Item> get allItems {
    final items = <Item>[];
    for (final entry in itemCounts.entries) {
      for (var i = 0; i < entry.value; i++) {
        items.add(entry.key);
      }
    }
    return items;
  }

  ItemStack? firstStackWithMatchingType(Item type) {
    for (final stack in _stacks) {
      if (stack.type == type) {
        return stack;
      }
    }
    return null;
  }

  int countOf(Item item) {
    var count = 0;
    for (final stack in _stacks) {
      if (stack.item == item) {
        count += stack.count;
      }
    }
    return count;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'size': size,
      'stacks': _stacks.map((s) => s.toJson()).toList(),
    };
  }
}

@immutable
class Inventory extends StackContainer {
  Inventory({required super.stacks}) : super(size: 25);
  const Inventory.empty() : super.empty(size: 25);
  Inventory.fromJson(super.json, super.items) : super.fromJson();

  // TODO(eseidel): Remove this, it does not preserve stack order.
  Inventory.fromCounts(Map<Item, int> itemCounts)
      : super.fromCounts(itemCounts: itemCounts, size: 25);

  @override
  int countOf(Item item) => itemCounts[item] ?? 0;

  Inventory copyWith({List<Item>? removed, List<Item>? added}) {
    final newItemCounts = itemCountsAfterEdits(
      removed: removed ?? [],
      added: added ?? [],
    );
    return Inventory.fromCounts(newItemCounts);
  }

  @override
  String toString() {
    return 'Inventory($itemCounts)';
  }
}

class GameStats {
  const GameStats({this.clicks = 0, this.timeInMilliseconds = 0});

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      clicks: json['clicks'] as int,
      timeInMilliseconds: json['timeInMilliseconds'] as int,
    );
  }
  final int clicks;
  final int timeInMilliseconds;

  GameStats copyAdding({required int clicks, required int timeInMilliseconds}) {
    return GameStats(
      clicks: clicks + this.clicks,
      timeInMilliseconds: timeInMilliseconds + this.timeInMilliseconds,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'clicks': clicks,
      'timeInMilliseconds': timeInMilliseconds,
    };
  }

  @override
  String toString() {
    return 'GameStats{clicks: $clicks, timeInMilliseconds: $timeInMilliseconds}';
  }
}

@immutable
class GameState {
  const GameState({
    required this.inventory,
    required this.skills,
    required this.meEnergy,
    required this.minionEnergy,
    required this.stats,
    required this.bench,
  });

  factory GameState.fromJson(Map<String, dynamic> json, ItemSet items) {
    return GameState(
      inventory:
          Inventory.fromJson(json['inventory'] as Map<String, dynamic>, items),
      skills: Skills(Map<Skill, double>.from(json['skills'] as Map)),
      meEnergy: json['meEnergy'] as int,
      minionEnergy: json['minionEnergy'] as int,
      stats: GameStats.fromJson(json['stats'] as Map<String, dynamic>),
      bench:
          CraftingBench.fromJson(json['bench'] as Map<String, dynamic>, items),
    );
  }

  const GameState.empty()
      : inventory = const Inventory.empty(),
        bench = const CraftingBench.empty(),
        skills = const Skills(),
        stats = const GameStats(),
        meEnergy = meMaxEnergy,
        minionEnergy = minionMaxEnergy;
  static const meMaxEnergy = 100;
  static const minionMaxEnergy = 100;

  final CraftingBench bench;
  final Inventory inventory;
  final Skills skills;
  final int meEnergy;
  final int minionEnergy;
  final GameStats stats;

  int get meHunger => meMaxEnergy - meEnergy;
  int get minionHunger => minionMaxEnergy - minionEnergy;

  GameState copyWith({
    Inventory? inventory,
    Skills? skills,
    int? meEnergy,
    int? minionEnergy,
    GameStats? stats,
    CraftingBench? bench,
  }) {
    return GameState(
      inventory: inventory ?? this.inventory,
      skills: skills ?? this.skills,
      meEnergy: meEnergy ?? this.meEnergy,
      minionEnergy: minionEnergy ?? this.minionEnergy,
      stats: stats ?? this.stats,
      bench: bench ?? this.bench,
    );
  }

  GameState copyApplying(ActionResult result) {
    return copyWith(
      inventory: inventory.copyWith(
        removed: result.removeItems,
        added: result.addItems,
      ),
      stats: stats.copyAdding(
        clicks: 1,
        timeInMilliseconds: result.timeInMilliseconds,
      ),
      skills: skills + result.skillChange,
      minionEnergy: minionEnergy + result.minionEnergyChange,
      meEnergy: meEnergy + result.meEnergyChange,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'inventory': inventory.toJson(),
      'skills': skills.skillToLevel,
      'meEnergy': meEnergy,
      'minionEnergy': minionEnergy,
      'stats': stats.toJson(),
      'bench': bench.toJson(),
    };
  }
}

// Mutable, handles rules
class Game {
  Game({int? seed})
      : _random = Random(seed),
        state = const GameState.empty();

  factory Game.fromJson(Map<String, dynamic> json, ItemSet items) {
    // TODO(eseidel): Handle seed
    return Game()
      ..state =
          GameState.fromJson(json['state'] as Map<String, dynamic>, items);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'state': state.toJson(),
    };
  }

  final Random _random;
  GameState state;

  void apply(Action action) {
    final context = ResolveContext(state, _random);
    final result = action.resolve(context);
    // print(result);
    if (result.action is Craft) {
      logger.info('CRAFT ${(result.action as Craft).recipe.outputs}');
    }
    state = state.copyApplying(result);
  }
}
