import 'dart:math';
import 'package:meta/meta.dart';

import 'package:dash_craft/inventory.dart';
import 'package:dash_craft/items.dart';

// MVP
// A thing which can simulate to peel 100 bananas
// Including gathering and

// * Give it a goal (e.g. 100 peeled bananas)
// * Give it actions (fetch, peel, discard, eat, etc.)
// * Simulate possible actions for the actor.
// * Separate SkillState from Inventory
// * SkillState (skill levels for both me and minion)
// * RecipeBook (all available recipes)
// * Inventory (stuff we have)
// * GameState? (clicks, time, goal)?

// Evaluate cost (time, clicks, energy, etc.) for a given item stack.

// enum Skill {
//   foodPrep,
//   gather,
//   minionFetch,
// }

@immutable
class Skills {
  final double foodPrep;

  final double gather;

  const Skills({this.foodPrep = 0, this.gather = 0});

  Skills copyWith({double? foodPrep}) {
    return Skills(foodPrep: foodPrep ?? this.foodPrep);
  }

  Skills operator +(Skills other) {
    return Skills(
      foodPrep: foodPrep + other.foodPrep,
      gather: gather + other.gather,
    );
  }

  @override
  String toString() {
    var values = [];
    if (foodPrep != 0) {
      values.add('foodPrep: $foodPrep');
    }
    if (gather != 0) {
      values.add('gather: $gather');
    }
    return 'Skills(${values.join(', ')})';
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
  Iterable<Item> get uniqueItems => counts.keys;

  Map<Item, int> get counts {
    var counts = <Item, int>{};
    for (var item in items) {
      var count = counts[item] ?? 0;
      counts[item] = count + 1;
    }
    return counts;
  }
}

// Actions types
// craft (use current tool, click craft)
// Send minion (click minion)
// Feed minion/me (drag pile onto)
// Burn (drag pile onto fire)
// discard (drag pile onto trash)
// equip (drag item onto slot)

class ActionResult {
  // Inventory changes
  // skill changes
  final Action action;
  final List<Item> addItems;
  final List<Item> removeItems;
  final int timeInMilliseconds;
  final Skills skillChange;

  final int meEnergyChange;
  final int minionEnergyChange;

  const ActionResult({
    required this.action,
    this.addItems = const [],
    this.removeItems = const [],
    this.meEnergyChange = 0,
    this.minionEnergyChange = 0,
    required this.timeInMilliseconds,
    Skills? skillChange,
  }) : skillChange = skillChange ?? const Skills();

  const ActionResult.empty()
      : action = const DummyAction(),
        addItems = const [],
        removeItems = const [],
        timeInMilliseconds = 0,
        meEnergyChange = 0,
        minionEnergyChange = 0,
        skillChange = const Skills();

  @override
  String toString() {
    var values = [];
    if (addItems.isNotEmpty) {
      values.add('addItems: $addItems');
    }
    if (removeItems.isNotEmpty) {
      values.add('removeItems: $removeItems');
    }
    if (meEnergyChange != 0) {
      values.add('meEnergyChange: $meEnergyChange');
    }
    if (minionEnergyChange != 0) {
      values.add('minionEnergyChange: $minionEnergyChange');
    }
    if (skillChange != const Skills()) {
      values.add('skillChange: $skillChange');
    }
    return 'ActionResult($action, ${values.join(', ')})';
  }
}

class ResolveContext {
  final Random random;
  final GameState state;
  ResolveContext(this.state, this.random);

  Skills get skills => state.skills;

  double nextDouble() => random.nextDouble();
  Item pickOne(List<Item> items) => items[random.nextInt(items.length)];
}

@immutable
abstract class Action {
  const Action();
  // type
  // click cost?
  // time cost?

  bool validate(GameState state);

  ActionResult resolve(ResolveContext context);
}

class DummyAction extends Action {
  const DummyAction();
  @override
  bool validate(GameState state) => true;
  @override
  ActionResult resolve(ResolveContext context) => const ActionResult.empty();
}

class Craft extends Action {
  final Recipe recipe;
  const Craft({required this.recipe});
  // Tool
  // specific inputs

  double successChance(Skills skills) {
    return 0.5;
  }

  double learningRate(Skills skills) {
    return 0.1;
  }

  int craftTimeMs(Skills skills) {
    return 1000;
  }

  @override
  bool validate(GameState state) {
    // Do we have the required resources?
    // Do we have the skill to execute this?
    // Do we have the energy to execute this?
    return true;
  }

  @override
  ActionResult resolve(ResolveContext context) {
    // Multipler for recipe?
    // Check space in inventory -- inventory is infinite for MVP.
    // Check tool level -- no such thing in MVP.
    // Check tool durability -- no such thing in MVP.
    // reduce tool durability -- no such thing in MVP.
    if (context.nextDouble() < successChance(context.skills)) {
      // Some successes can give extra items?
      return ActionResult(
        action: this,
        timeInMilliseconds: craftTimeMs(context.skills),
        addItems: recipe.outputs,
        removeItems: recipe.inputs.toList(),
      );
    } else {
      // Does goop come in multiples?  How much?
      return ActionResult(
        action: this,
        timeInMilliseconds: craftTimeMs(context.skills),
        removeItems: recipe.inputs.toList(),
        addItems: recipe.failureGivesGoop ? [goop] : [],
        skillChange: Skills(foodPrep: learningRate(context.skills)),
      );
    }
    // Learn about the recipe requirements if necessary
    // If learned, show recipe on screen.
  }
}

enum MinionTask {
  gather,
  lumberjack,
  hunt,
  fish,
  treasureHunt,
}

class SendMinion extends Action {
  // with tool?

  // communication

  MinionTask get task {
    // compute from context.
    return MinionTask.gather;
  }

  @override
  bool validate(GameState state) {
    // Ensure we have the tool we claim to?
    // Always possible to send minion on a gathering task.
    return true;
  }

  Iterable<Item> availableGatherItems(Skills skills) => gatherItems.where(
      (i) => i.gatherSkill != null ? i.gatherSkill! <= skills.gather : false);

  int gatherTimeMs(ResolveContext context) {
    if (context.state.minionEnergy < 1) {
      return 1000;
    }
    return 100;
  }

  @override
  ActionResult resolve(ResolveContext context) {
    // Is this a one-off, or a repeating task?
    var items = availableGatherItems(context.skills);
    return ActionResult(
      action: this,
      addItems: [context.pickOne(items.toList())],
      timeInMilliseconds: gatherTimeMs(context),
      skillChange: const Skills(gather: 0.1),
      minionEnergyChange: -1,
    );

    // lumberjack
    // hunt
    // fish
    // treasure
  }

  @override
  String toString() {
    return 'SendMinion{task: $task}';
  }
}

enum TargetHuman {
  me,
  minion,
}

class Feed extends Action {
  // inputs
  final List<Item> inputs;
  final TargetHuman target;

  const Feed({required this.inputs, required this.target});

  @override
  bool validate(GameState state) {
    // Do we have the food we claim to?
    // Does the target have sufficent hunger?
    // Are all items edible?
    return true;
  }

  @override
  ActionResult resolve(ResolveContext context) {
    // Eat as much as possible.
    // Remove any inputs we consumed.
    var totalEnergy = inputs
        .map((i) => i.energy ?? 0)
        .reduce((value, element) => value + element);
    if (target == TargetHuman.me) {
      return ActionResult(
        action: this,
        timeInMilliseconds: 0,
        removeItems: inputs,
        meEnergyChange: totalEnergy,
      );
    } else {
      return ActionResult(
        action: this,
        timeInMilliseconds: 0,
        removeItems: inputs,
        minionEnergyChange: totalEnergy,
      );
    }
  }

  @override
  String toString() {
    return 'Feed{inputs: $inputs, target: $target}';
  }
}

// Mutable, does planning.
abstract class Planner {
  List<Craft> possibleCrafts(Inventory inventory) {
    // var counts = inventory.counts;
    // for (var recipe in recipes) {
    //   // Check skill.
    //   if (recipe.inputs.every((i) => counts[i] != null && counts[i]! > 0)) {
    //     return [Craft(recipe: recipe)];
    //   }
    // }
    return [];
  }

  List<SendMinion> possibleSendMinions(Inventory inventory) {
    return [SendMinion()];
  }

  Iterable<Feed> possibleFeeds(GameState state) sync* {
    for (var item in state.inventory.uniqueItems) {
      if (item.energy != null) {
        if (item.energy! <= state.meHunger) {
          yield Feed(inputs: [item], target: TargetHuman.me);
        }
        if (item.energy! <= state.minionHunger) {
          yield Feed(inputs: [item], target: TargetHuman.minion);
        }
      }
    }
    // For all food items
    // If < than the hunger
  }

  Iterable<Action> possibleActions(GameState state) sync* {
    // all possible recipes
    for (var craft in possibleCrafts(state.inventory)) {
      yield craft;
    }
    // all possible minion actions
    for (var send in possibleSendMinions(state.inventory)) {
      yield send;
    }
    // all possible edibles to each target
    for (var feed in possibleFeeds(state)) {
      yield feed;
    }
  }

  Action plan(GameState game);
}

class RandomPlanner extends Planner {
  final Random random;
  RandomPlanner({int? seed}) : random = Random(seed);

  @override
  Action plan(GameState state) {
    var actions = possibleActions(state).toList();
    return actions[random.nextInt(actions.length)];
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

void main() {
  print("Simulating...");
  var game = Game(seed: 0);
  var planner = RandomPlanner(seed: 0);
  bool haveMetGoal(GameState game) {
    return game.inventory.countOf(banana) >= 100;
  }

  while (!haveMetGoal(game.state)) {
    var action = planner.plan(game.state);
    game.apply(action);
  }
  print("Done!");
  print("Me Energy: ${game.state.meEnergy}");
  print("Minion Energy: ${game.state.minionEnergy}");
  print("Stats: ${game.state.stats}");
  print("Skills: ${game.state.skills}");
  print("Inventory: ${game.state.inventory.counts}");
}

// class Goal {
//   ItemStack items;
//   Goal({this.items});
// }

// class Reward {

// }

// class Quest {
//   final Goal goal;
//   final Reward? reward;
//   Quest( this.goal {this.reward});
// }

// Attempt at writing out tutorial quests.
// var quests = [
//   Quest(Goal.empty(), reward: [ItemStack(type: cookedRedMeat, count: 7)]),
//   Quest(Goal(meEnergy: 100), reward: [ItemStack(type: banana, count: 4)]),
//   // Peel the bananas, eat one of them (2 turn to goop)
//   Quest(Goal.empty(), reward: [ItemStack(type: orange, count: 15)]),
//   Quest(Goal(mealPrep:15), reward: [ItemStack(type: walnut, count: 5), ItemStack(type: stone, count: 1)]),
//   // 57% chance oranges at 6.2
//   Quest(Goal(items: ItemStack(type: walnutKernel, count: 2)), reward: [ItemStack(type: stone, count: 2)]),
//   // Get recipe book
//   Quest(Goal(items: ItemStack(type: sharpStone, count: 1)), reward: [ItemStack(type: banana, count: 5)]),
//   // Tool crafting unlocks.
//   Quest(Goal(items: ItemStack(type: slicedBanana, count: 1))),
//   // Minion unlocks.
//   Quest(Goal(items: ItemStack(type: coconut, count: 2))),
//   // Currently gathering is 8.7, increasing at 0.6 for stones or oranges, 0.4 for coconuts 0.3 for bananas.
//   Quest(Goal(minionGathering: 19.0))
// ]
