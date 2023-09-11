import 'dart:math';

import 'package:dash_craft/action.dart';
import 'package:dash_craft/game.dart';
import 'package:dash_craft/logger.dart';
import 'package:dash_craft/plan/goal.dart';
import 'package:dash_craft/plan/planner.dart';

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
  MTCS({this.explorationWeight = 1.0, int? seed, this.maxSimulationDepth = 100})
      : random = Random(seed);
  final Map<T, double> _rewards = {}; // aka 'Q'
  final Map<T, double> _visits = {}; // aka 'N'
  final Map<T, List<T>> _children = {};
  final double explorationWeight;
  final int maxSimulationDepth;
  final Random random;

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
    final exploredChildren = _children[node];
    if (exploredChildren == null) {
      logger.info('Not explored any children!');
      return node.randomChild(random)!;
    }

    double score(T child) {
      final visits = _visits[child] ?? 0;
      if (visits == 0) {
        return double.negativeInfinity;
      }
      final reward = _rewards[child] ?? 0;
      // print(
      //     "${(child as ActionNode).action} reward: ${reward.toStringAsFixed(2)} visits: $visits");
      return reward / visits;
    }

    final choice =
        exploredChildren.reduce((a, b) => score(a) > score(b) ? a : b);
    // print(
    //     "# Choose ${(choice as ActionNode).action} with score ${score(choice).toStringAsPrecision(6)}");
    return choice;
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
    final path = <T>[];
    var current = node;
    while (true) {
      path.add(current);
      final exploredChildren = _children[current] ?? [];
      if (exploredChildren.isEmpty) {
        return path;
      }
      final unexplored =
          Set<T>.from(exploredChildren).difference(Set.from(_children.keys));
      if (unexplored.isNotEmpty) {
        // Should this be a random selection?
        path.add(unexplored.last);
        return path;
      }
      current = _utcSelect(current); // decend a layer deeper
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
    var current = node;
    while (!current.isLeaf && depthRemaining > 0) {
      depthRemaining--;
      current = current.randomChild(random)!;
    }
    return current.reward;
  }

  void _backpropagate(List<T> path, double reward) {
    // Update the rewards and visits for each node in the path.
    for (final node in path.reversed) {
      final existingReward = _rewards[node] ?? 0;
      _rewards[node] = existingReward + reward;
      final existingVisits = _visits[node] ?? 0;
      _visits[node] = existingVisits + 1;
    }
  }

  bool _allChildrenExpanded(T node) {
    final children = _children[node];
    if (children == null) {
      return false;
    }
    return children.every(_children.containsKey);
  }

// UTC is an algorithm from
// https://link.springer.com/chapter/10.1007/11871842_29
// The purpose is to balance exploration and exploitation
// of known high-value paths.

  T _utcSelect(T node) {
    // Select a child of `node` balancing exploration and exploitation.
    assert(_allChildrenExpanded(node), 'Not all children expanded');
    // Should this be ln? rather than log? for UCB1?
    final logOfParentVisits = log(_visits[node]!);

    // I believe this is UCB1?
    // https://cesa-bianchi.di.unimi.it/Pubblicazioni/ml-02.pdf
    double uct(T child) {
      // Upper confidence bound for the subtree.
      final visits = _visits[child]!;
      // Expansion tries to continue down promising subtrees.
      final expansionTerm = _rewards[child]! / visits;
      // Exploration tries to preserve log ratio of parent play throughs vs. child playthroughs.
      // If my parent has been visited a lot then my siblings have been
      // so the numerator is large relative to the denominator.
      // which is the number of times I've been visited.
      final explorationTerm =
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

  @override
  bool get hasChildren => collectChildren().isNotEmpty;

  @override
  Iterable<ActionNode> collectChildren() {
    _childrenCache ??= ActionGenerator.possibleActions(state).map((action) {
      final context = ResolveContext(state, random);
      final result = action.resolve(context);
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
    final children = collectChildren();
    return children.elementAt(random.nextInt(children.length));
  }

  @override
  double get reward => goal.scoreForState(state);

  @override
  String toString() {
    return 'ActionNode{action: $action, state: $state, reward: $reward}';
  }

  // This is OK for now, we're only mutating _childrenCache, which we
  // do not compare.
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
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
  MonteCarloTreeSearchPlanner(
    this.goal, {
    double explorationWeight = 1.4,
    int? seed,
  })  : _mtcs =
            MTCS<ActionNode>(explorationWeight: explorationWeight, seed: seed),
        _random = Random(seed);
  final int _simulationsPerTurn = 50;
  ActionNode? _root;
  final MTCS<ActionNode> _mtcs;
  final Goal goal;
  final Random _random;

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

    for (var i = 0; i < _simulationsPerTurn; i++) {
      _mtcs.simulate(_root!);
    }
    _root = _mtcs.choose(_root!);
    _mtcs.pruneCaches(_root!.depth);
    return _root!.action;
  }
}
