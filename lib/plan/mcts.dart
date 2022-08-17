import 'package:dash_craft/game.dart';

import 'package:dash_craft/action.dart';

import 'planner.dart';

class MCTSNode {
  final Action action;
  final GameState state;
  final MCTSNode? parent;
  final List<MCTSNode> children = [];
  // int visits = 0;
  // int wins = 0;
  // double winRate = 0.0;
  // double ucbValue = 0.0; // needed?
}

MCTSNode buildNode(GameState state, int exploreDepth) {
  for (var action in possibleActions(state)) {}
  // Explore all possible actions up to N depth.
  // Evaluate fitness function for each.
  // Prune any branches with low fitness after M depth.
}

class MonteCarloTreeSearchPlanner extends Planner {
  @override
  Action plan(GameState state) {
    var explorDepth = 4;
    var root = buildNode(state, explorDepth);

    // Walk the tree, pick the branch with long-term highest payout.

    // TODO: implement plan
    throw UnimplementedError();
  }
}
