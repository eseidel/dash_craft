import 'package:meta/meta.dart';
import 'dart:math';

import 'action.dart';
import 'items.dart';

enum Skill {
  foodPrep,
  toolCrafting,
  gather,
}

@immutable
class Skills {
  final Map<Skill, double> skillToLevel;

  const Skills([this.skillToLevel = const {}]);

  double operator [](Skill skill) => skillToLevel[skill] ?? 0.0;
  void operator []=(Skill skill, double level) => skillToLevel[skill] = level;

  Skills copyWith(Map<Skill, double> skills) {
    var newSkills = Map<Skill, double>.from(skillToLevel);
    newSkills.addAll(skills);
    return Skills(newSkills);
  }

  Skills operator +(Skills other) {
    var newSkills = Map<Skill, double>.from(skillToLevel);
    for (var skill in other.skillToLevel.keys) {
      var level = newSkills[skill] ?? 0.0;
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
class Inventory {
  final Map<Item, int> itemToCount;

  static Map<Item, int> toItemCounts(List<Item> items) {
    var itemToCount = <Item, int>{};
    for (var item in items) {
      itemToCount[item] = (itemToCount[item] ?? 0) + 1;
    }
    return Map<Item, int>.unmodifiable(itemToCount);
  }

  const Inventory() : itemToCount = const {};

  const Inventory.fromCounts(this.itemToCount);
  Inventory.fromItems(List<Item> items) : itemToCount = toItemCounts(items);

  int countOf(Item item) => itemToCount[item] ?? 0;

  Inventory copyWith({List<Item>? removed, List<Item>? added}) {
    var newItemCounts = Map<Item, int>.from(itemToCount);
    if (removed != null && removed.isNotEmpty) {
      for (var toRemove in removed) {
        assert(newItemCounts[toRemove] != null);
        assert(newItemCounts[toRemove]! > 0);
        var newCount = (newItemCounts[toRemove] ?? 0) - 1;
        // Important to remove the key if the count is 0 otherwise
        // uniqueItems will be wrong.
        if (newCount == 0) {
          newItemCounts.remove(toRemove);
        } else {
          newItemCounts[toRemove] = newCount;
        }
      }
    }
    if (added != null && added.isNotEmpty) {
      for (var toAdd in added) {
        newItemCounts[toAdd] = (newItemCounts[toAdd] ?? 0) + 1;
      }
    }
    return Inventory.fromCounts(newItemCounts);
  }

  // This will just be item (types) when Inventory hold stacks?
  Iterable<Item> get uniqueItems {
    assert(itemToCount.entries.every((element) => element.value > 0));
    return itemToCount.keys;
  }

  @override
  String toString() {
    return 'Inventory($itemToCount)';
  }
}

// class GameStateBuilder {
//   final GameState initialState;
//   final Random random;

//   List<Item> removed = [];
//   List<Item> added = [];

//   double nextDouble() => 1.0;

//   GameStateBuilder.from(this.initialState, this.random);

//   Skills get skills => initialState.skills;

//   void addItem(Item item) => added.add(item);
//   void removeItem(Item item) => removed.add(item);

//   GameState build() {
//     return initialState.copyWith(
//       inventory:
//           initialState.inventory.copyWith(removed: removed, added: added),
//       stats: initialState.stats.copyAdding(timeInMilliseconds: 200, clicks: 1),
//     );
//   }
// }

class GameStats {
  final int clicks;
  final int timeInMilliseconds;

  const GameStats({this.clicks = 0, this.timeInMilliseconds = 0});

  GameStats copyAdding({required int clicks, required int timeInMilliseconds}) {
    return GameStats(
        clicks: clicks + this.clicks,
        timeInMilliseconds: timeInMilliseconds + this.timeInMilliseconds);
  }

  @override
  String toString() {
    return 'GameStats{clicks: $clicks, timeInMilliseconds: $timeInMilliseconds}';
  }
}

@immutable
class GameState {
  static const meMaxEnergy = 100;
  static const minionMaxEnergy = 100;

  final Inventory inventory;
  final Skills skills;
  final int meEnergy;
  final int minionEnergy;
  final GameStats stats;

  int get meHunger => meMaxEnergy - meEnergy;
  int get minionHunger => minionMaxEnergy - minionEnergy;

  const GameState(
      {required this.inventory,
      required this.skills,
      required this.meEnergy,
      required this.minionEnergy,
      required this.stats});

  const GameState.empty()
      : inventory = const Inventory(),
        skills = const Skills(),
        stats = const GameStats(),
        meEnergy = 0,
        minionEnergy = 0;

  GameState copyWith(
      {Inventory? inventory,
      Skills? skills,
      int? meEnergy,
      int? minionEnergy,
      GameStats? stats}) {
    return GameState(
      inventory: inventory ?? this.inventory,
      skills: skills ?? this.skills,
      meEnergy: meEnergy ?? this.meEnergy,
      minionEnergy: minionEnergy ?? this.minionEnergy,
      stats: stats ?? this.stats,
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
}

// Mutable, handles rules
class Game {
  final Random _random;
  GameState state;

  Game({int? seed})
      : _random = Random(seed),
        state = const GameState.empty();

  void apply(Action action) {
    var context = ResolveContext(state, _random);
    var result = action.resolve(context);
    // print(result);
    if (result.action is Craft) {
      print("CRAFT ${(result.action as Craft).recipe.outputs}");
    }
    state = state.copyApplying(result);
  }
}
