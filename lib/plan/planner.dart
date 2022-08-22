import '../game.dart';
import '../action.dart';
import '../inventory.dart';

import 'dart:math';

class ActionGenerator {
  static Iterable<Craft> possibleCrafts(
      Inventory inventory, Skills skills) sync* {
    var counts = inventory.asMap();
    for (var recipe in recipes) {
      if (recipe.skillRequired <= skills[recipe.skill] &&
          recipe.inputs.entries.every(
              (e) => counts[e.key] != null && counts[e.key]! >= e.value)) {
        yield Craft(recipe: recipe);
      }
    }
  }

  static List<SendMinion> possibleSendMinions(Inventory inventory) {
    // TODO: Other send types depending on available items.
    return [SendMinion()];
  }

  static Iterable<Feed> possibleFeeds(GameState state) sync* {
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

  static Iterable<Action> possibleActions(GameState state) sync* {
    // all possible recipes
    for (var craft in possibleCrafts(state.inventory, state.skills)) {
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
}

// Mutable, does planning.
// Input a goal.
// Output is successive actions to achieve the goal.
abstract class Planner {
  Action plan(GameState state);
}

class RandomPlanner extends Planner {
  final Random random;
  RandomPlanner({int? seed}) : random = Random(seed);

  @override
  Action plan(GameState state) {
    var actions = ActionGenerator.possibleActions(state).toList();
    return actions[random.nextInt(actions.length)];
  }
}

// double fitnessFunction(GameState state) {
//   double fitness = 0.0;

//   fitness += state.skills.totalPercent;
//   // fitness += state.totalEnergyPercent;
//   // fitness += state.inventorySizePercent;
//   // Inventory
//   // Tool power levels
//   // fitness += state.inventory.availableToolPowerLevelsPercent;
//   // // Tool durability levels
//   // fitness += state.inventory.toolDurabilityPercent;
//   // Food energy
//   // Burn energy
//   // existance of various tools?
//   // total number of items (up to a point)?
//   return fitness;
// }
