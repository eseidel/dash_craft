import 'package:meta/meta.dart';
import 'dart:math';

import 'action.dart';
import 'items.dart';

enum Skill {
  foodPrep,
  gather,
  minionFetch,
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
    return 'Skills(${Skill.values.map((s) => '$s: ${this[s]}').join(', ')})';
  }
}

@immutable
class Inventory {
  final List<Item> items;

  const Inventory({this.items = const <Item>[]});

  int countOf(Item item) => items.where((i) => i == item).length;

  Inventory copyWith({List<Item>? removed, List<Item>? added}) {
    var newItems = List<Item>.from(items);
    if (removed != null) {
      for (var toRemove in removed) {
        newItems.remove(toRemove);
      }
    }
    if (added != null) {
      newItems.addAll(added);
    }
    return Inventory(items: newItems);
  }

  // This will just be item (types) when Inventory hold stacks?
  Iterable<Item> get uniqueItems => asMap().keys;

  Map<Item, int> asMap() {
    var counts = <Item, int>{};
    for (var item in items) {
      var count = counts[item] ?? 0;
      counts[item] = count + 1;
    }
    return counts;
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
}

// Mutable, handles rules
class Game {
  final Random _random;
  GameState state;

  Game({int? seed})
      : _random = Random(seed),
        state = const GameState.empty();

  GameState stateByApplying(ActionResult result) {
    return state.copyWith(
      inventory: state.inventory.copyWith(
        removed: result.removeItems,
        added: result.addItems,
      ),
      stats: state.stats.copyAdding(
        clicks: 1,
        timeInMilliseconds: result.timeInMilliseconds,
      ),
      skills: state.skills + result.skillChange,
      minionEnergy: state.minionEnergy + result.minionEnergyChange,
      meEnergy: state.meEnergy + result.meEnergyChange,
    );
  }

  void apply(Action action) {
    var context = ResolveContext(state, _random);
    var result = action.resolve(context);
    print(result);
    state = stateByApplying(result);
  }
}
