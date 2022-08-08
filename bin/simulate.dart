import 'dart:math';
import 'package:meta/meta.dart';

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

import 'package:dash_craft/inventory.dart';
import 'package:dash_craft/items.dart';

@immutable
class Skills {
  final double foodPrep;

  const Skills({this.foodPrep = 0});

  Skills copyWith({double? foodPrep}) {
    return Skills(foodPrep: foodPrep ?? this.foodPrep);
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
}

// Actions types
// craft (use current tool, click craft)
// Send minion (click minion)
// Feed minion/me (drag pile onto)
// Burn (drag pile onto fire)
// discard (drag pile onto trash)
// equip (drag item onto slot)

@immutable
abstract class Action {
  const Action();
  // type
  // click cost?
  // time cost?

  bool validate();

  void apply(GameStateBuilder builder);
}

class Craft extends Action {
  final Recipe recipe;
  const Craft({required this.recipe});
  // Tool
  // specific inputs

  double successChance(Skills skills) {
    return 0.5;
  }

  @override
  bool validate() {
    // Do we have the required resources?
    // Do we have the skill to execute this?
    // Do we have the energy to execute this?
    return true;
  }

  @override
  void apply(GameStateBuilder builder) {
    // Multipler for recipe?
    // Check space in inventory -- inventory is infinite for MVP.
    // Check tool durability -- no such thing in MVP.
    // Check tool level -- no such thing in MVP.
    // Take items
    // Check success percent.
    bool successful = builder.nextDouble() < successChance(builder.skills);
    // If successful, add results to inventory.
    // Handle multiple outputs.
    // Do learning
    // Learn about the recipe requirements if necessary
    // If learned, show recipe on screen.
    // If was food, give goop!
    // Does goop come in multiples?
  }
}

enum MinionTask {
  gathering,
  lumberjack,
  hunting,
  fishing,
  treasureHunting,
}

class SendMinion extends Action {
  // with tool?

  // communication

  @override
  bool validate() {
    // Ensure we have the tool we claim to?
    // Always possible to send minion on a gathering task.
    return true;
  }

  void doGather(GameStateBuilder builder) {
    builder.addItem(banana);
  }

  @override
  void apply(GameStateBuilder builder) {
    // Is this a one-off, or a repeating task?
    doGather(builder);
    // lumberjack
    // hunt
    // fish
    // treasure
  }
}

class Feed extends Action {
  // inputs
  final List<Item> inputs;

  const Feed({required this.inputs});

  @override
  bool validate() {
    // Do we have the food we claim to?
    return true;
  }

  @override
  void apply(GameStateBuilder builder) {
    // Eat as much as possible.
    // Remove any inputs we consumed.
  }
}

// Mutable, does planning.
abstract class Planner {
  List<Craft> possibleCrafts(Inventory inventory) {
    return [];
  }

  List<SendMinion> possibleSendMinions(Inventory inventory) {
    return [SendMinion()];
  }

  List<Feed> possibleFeeds(Inventory inventory) {
    return [];
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
    for (var feed in possibleFeeds(state.inventory)) {
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

class GameStateBuilder {
  final GameState initialState;

  List<Item> removed = [];
  List<Item> added = [];

  double nextDouble() => 1.0;

  GameStateBuilder.from(this.initialState);

  Skills get skills => initialState.skills;

  void addItem(Item item) => added.add(item);
  void removeItem(Item item) => removed.add(item);

  GameState build() {
    return initialState.copyWith(
      inventory:
          initialState.inventory.copyWith(removed: removed, added: added),
    );
  }
}

@immutable
class GameState {
  final Inventory inventory;
  final Skills skills;
  final double meEnergy;
  final double minionEnergy;

  const GameState(
      {required this.inventory,
      required this.skills,
      required this.meEnergy,
      required this.minionEnergy});

  const GameState.empty()
      : inventory = const Inventory(),
        skills = const Skills(),
        meEnergy = 0,
        minionEnergy = 0;

  GameState copyWith(
      {Inventory? inventory,
      Skills? skills,
      double? meEnergy,
      double? minionEnergy}) {
    return GameState(
      inventory: inventory ?? this.inventory,
      skills: skills ?? this.skills,
      meEnergy: meEnergy ?? this.meEnergy,
      minionEnergy: minionEnergy ?? this.minionEnergy,
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
    var builder = GameStateBuilder.from(state);
    action.apply(builder);
    state = builder.build();
  }
}

void main() {
  print("Simulating...");
  var game = Game(seed: 0);
  var planner = RandomPlanner(seed: 0);
  bool haveMetGoal(GameState game) {
    return game.inventory.countOf(banana) > 100;
  }

  while (!haveMetGoal(game.state)) {
    var action = planner.plan(game.state);
    game.apply(action);
  }
  print("Done!");
}
