import 'dart:math';

import 'package:logic/action.dart';
import 'package:logic/game.dart';
import 'package:logic/rules.dart';

class ActionGenerator {
  ActionGenerator(this.doc);

  final DOC doc;

  Iterable<Craft> possibleCrafts(
    Inventory inventory,
    Skills skills,
  ) sync* {
    final counts = inventory.itemToCount;
    for (final recipe in doc.recipes.all) {
      if (recipe.skillRequired <= skills[recipe.skill] &&
          recipe.inputs.entries.every(
            (e) => counts[e.key] != null && counts[e.key]! >= e.value,
          )) {
        yield Craft(recipe: recipe);
      }
    }
  }

  List<SendMinion> possibleSendMinions(Inventory inventory) {
    // TODO(eseidel): Other send types depending on available items.
    return [SendMinion(doc: doc)];
  }

  Iterable<Feed> possibleFeeds(GameState state) sync* {
    for (final item in state.inventory.uniqueItems) {
      final energy = item.energy;
      if (energy == null) {
        continue;
      }
      if (energy <= state.meHunger) {
        yield Feed(inputs: [item], target: TargetHuman.me);
      }
      if (energy <= state.minionHunger) {
        yield Feed(inputs: [item], target: TargetHuman.minion);
      }
    }
  }

  Iterable<Action> possibleActions(GameState state) sync* {
    // all possible recipes
    for (final craft in possibleCrafts(state.inventory, state.skills)) {
      yield craft;
    }
    // all possible minion actions
    for (final send in possibleSendMinions(state.inventory)) {
      yield send;
    }
    // all possible edibles to each target
    for (final feed in possibleFeeds(state)) {
      yield feed;
    }
  }
}

// Mutable, does planning.
// Input a goal.
// Output is successive actions to achieve the goal.
// ignore: one_member_abstracts
abstract class Planner {
  Action plan(GameState state);
}

class RandomPlanner extends Planner {
  RandomPlanner({required this.actionGenerator, int? seed})
      : random = Random(seed);
  final Random random;
  final ActionGenerator actionGenerator;

  @override
  Action plan(GameState state) {
    final actions = actionGenerator.possibleActions(state).toList();
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
