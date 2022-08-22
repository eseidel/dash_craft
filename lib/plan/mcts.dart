import 'package:dash_craft/game.dart';

import 'package:dash_craft/action.dart';

import 'planner.dart';
import 'goal.dart';
import 'dart:math';

// Inspired by https://gist.github.com/qpwo/c538c6f73727e254fdc7fab81024f6e1

// subclasses are also required to implement hashCode
// and operator == so they can be used as keys in a Map.
abstract class Node<T extends Node<T>> {
  bool get hasChildren;
  Iterable<T> collectChildren();
  T? randomChild(Random random);

  // for pruning
  int get depth;

  double get reward;

  bool get isLeaf => !hasChildren;
}

class MTCS<T extends Node<T>> {
  final Map<T, double> _rewards = {}; // aka 'Q'
  final Map<T, double> _visits = {}; // aka 'N'
  final Map<T, List<T>> _children = {};
  final double explorationWeight;
  final int maxSimulationDepth;
  final Random random;

  MTCS({this.explorationWeight = 1.0, int? seed, this.maxSimulationDepth = 100})
      : random = Random(seed);

  void pruneCaches(int depth) {
    _rewards.removeWhere((node, _) => node.depth < depth);
    _visits.removeWhere((node, _) => node.depth < depth);
    _children.removeWhere((node, _) => node.depth < depth);
  }

  T choose(T node) {
    // Choose a move in the game (best child node).
    if (!node.hasChildren) {
      throw Exception('Choose called on a node with no children.');
    }
    // We've not explored any children, just pick a random one.
    var exploredChildren = _children[node];
    if (exploredChildren == null) {
      return node.randomChild(random)!;
    }

    double score(T child) {
      double visits = _visits[child] ?? 0;
      if (visits == 0) {
        return double.negativeInfinity;
      }
      double reward = _rewards[child] ?? 0;
      return reward / visits;
    }

    return exploredChildren.reduce((a, b) => score(a) > score(b) ? a : b);
  }

  void simulate(T node) {
    // Make the tree one layer better.  Train for one interation.
    final path = _select(node);
    final leaf = path.last;
    _expand(leaf);
    final reward = _simulate(leaf);
    _backpropagate(path, reward);
  }

  List<T> _select(T node) {
    // Find and unexplored decendent of the node.
    var path = <T>[];
    while (true) {
      path.add(node);
      var exploredChildren = _children[node] ?? [];
      if (exploredChildren.isEmpty) {
        return path;
      }
      final unexplored =
          Set.from(exploredChildren).difference(Set.from(_children.keys));
      if (unexplored.isNotEmpty) {
        // Should this be a random selection?
        path.add(unexplored.last);
        return path;
      }
      node = _utcSelect(node); // decend a layer deeper
    }
  }

  void _expand(T node) {
    // Update the _children map with children of `node`.
    if (_children[node] != null) {
      return; // Already expanded.
    }
    _children[node] = node.collectChildren().toList();
  }

  double _simulate(T node) {
    // Randomly decend the choice tree until we reach a leaf
    // or hit our max depth and return the reward.
    var depthRemaining = maxSimulationDepth;
    while (!node.isLeaf && depthRemaining > 0) {
      depthRemaining--;
      node = node.randomChild(random)!;
    }
    return node.reward;
  }

  void _backpropagate(List<T> path, double reward) {
    // Update the rewards and visits for each node in the path.
    for (var node in path.reversed) {
      final existingReward = _rewards[node] ?? 0;
      _rewards[node] = existingReward + reward;
      final existingVisits = _visits[node] ?? 0;
      _visits[node] = existingVisits + 1;
    }
  }

  bool _allChildrenExpanded(T node) {
    var children = _children[node];
    if (children == null) {
      return false;
    }
    return children.every((child) => _children.containsKey(child));
  }

// UTC is an algorithm from
// https://link.springer.com/chapter/10.1007/11871842_29
// The purpose is to balance exploration and exploitation
// of known high-value paths.

  T _utcSelect(T node) {
    // Select a child of `node` balancing exploration and exploitation.
    assert(_allChildrenExpanded(node));
    // Should this be ln? rather than log? for UCB1?
    final logOfParentVisits = log(_visits[node]!);

    // I believe this is UCB1?
    // https://cesa-bianchi.di.unimi.it/Pubblicazioni/ml-02.pdf
    double uct(T child) {
      // Upper confidence bound for the subtree.
      final visits = _visits[child]!;
      // Expansion tries to continue down promising subtrees.
      var expansionTerm = _rewards[child]! / visits;
      // Exploration tries to preserve log ratio of parent play throughs vs. child playthroughs.
      // If my parent has been visited a lot then my siblings have been
      // so the numerator is large relative to the denominator.
      // which is the number of times I've been visited.
      var explorationTerm =
          explorationWeight * sqrt(logOfParentVisits / visits);
      return expansionTerm + explorationTerm;
    }

    return _children[node]!.reduce((a, b) => uct(a) > uct(b) ? a : b);
  }
}

// MCTSNode buildNode(GameState state, int exploreDepth) {
//   for (var action in possibleActions(state)) {}
//   // Explore all possible actions up to N depth.
//   // Evaluate fitness function for each.
//   // Prune any branches with low fitness after M depth.
// }

class ActionNode extends Node<ActionNode> {
  // What action was taken from our parent to get here?
  final Action action;
  // Current game state at this Node.
  final Goal goal;
  final GameState state;
  final Random random;
  List<ActionNode>? _childrenCache;
  @override
  final int depth;
  @override
  final int hashCode;

  ActionNode({
    required this.action,
    required this.state,
    required this.goal,
    required this.depth,
    required this.random,
  })
  // Faster to compute the hashcode up front and cache it.
  // This is possible since everything is immutable.
  : hashCode =
            action.hashCode ^ state.hashCode ^ goal.hashCode ^ depth.hashCode;

  @override
  bool get hasChildren => collectChildren().isNotEmpty;

  @override
  Iterable<ActionNode> collectChildren() {
    _childrenCache ??= ActionGenerator.possibleActions(state).map((action) {
      var context = ResolveContext(state, random);
      var result = action.resolve(context);
      return ActionNode(
        action: action,
        state: state.copyApplying(result),
        goal: goal,
        depth: depth + 1,
        random: random,
      );
    }).toList();
    return _childrenCache!;
  }

  @override
  ActionNode? randomChild(Random random) {
    var children = collectChildren();
    return children.elementAt(random.nextInt(children.length));
  }

  @override
  double get reward => goal.scoreForState(state);

  @override
  String toString() {
    return 'ActionNode{action: $action, state: $state, reward: $reward}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionNode &&
          runtimeType == other.runtimeType &&
          depth == other.depth &&
          action == other.action &&
          state == other.state &&
          goal == other.goal;
}

class MonteCarloTreeSearchPlanner extends Planner {
  final int _simulationsPerTurn = 50;
  ActionNode? _root;
  final MTCS<ActionNode> _mtcs;
  final Goal goal;
  final Random _random;

  MonteCarloTreeSearchPlanner(this.goal,
      {double explorationWeight = 0.5, int? seed})
      : _mtcs =
            MTCS<ActionNode>(explorationWeight: explorationWeight, seed: seed),
        _random = Random(seed);

  @override
  Action plan(GameState state) {
    _root ??= ActionNode(
      action: const DummyAction(),
      state: state,
      goal: goal,
      depth: 0,
      random: _random,
    );
    // Update root every time with the current state.
    // Otherwise we'll plan impossible actions?
    _root = ActionNode(
      action: _root!.action,
      state: state,
      goal: goal,
      depth: _root!.depth,
      random: _random,
    );

    for (int i = 0; i < _simulationsPerTurn; i++) {
      _mtcs.simulate(_root!);
    }
    _root = _mtcs.choose(_root!);
    _mtcs.pruneCaches(_root!.depth);
    return _root!.action;
  }
}
