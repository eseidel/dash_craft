// ignore_for_file: avoid_print

import 'package:args/args.dart';
import 'package:dash_craft/game.dart';
import 'package:dash_craft/items.dart';
import 'package:dash_craft/plan/goal.dart';
import 'package:dash_craft/plan/mcts.dart';

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

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption(
      'seed',
      abbr: 's',
      help: 'Seed for random number generator.',
    );
  final results = parser.parse(args);
  final seed = int.tryParse(results['seed'] as String? ?? '');

  print('Simulating...');
  final game = Game(seed: seed);
  final goal = Goal({stone: 100});
  final planner = MonteCarloTreeSearchPlanner(goal, seed: seed);

  var moveNumber = 0;

  while (!goal.haveMet(game.state)) {
    final action = planner.plan(game.state);
    game.apply(action);
    moveNumber++;
    if (moveNumber % 100 == 0) {
      print('Move $moveNumber');
      print(game.state.skills);
      print(game.state.inventory);
    }
  }
  print('Done!');
  print('Me Energy: ${game.state.meEnergy}');
  print('Minion Energy: ${game.state.minionEnergy}');
  print('Stats: ${game.state.stats}');
  print('Skills: ${game.state.skills}');
  print('Inventory: ${game.state.inventory.itemToCount}');
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
