import '../action.dart';
import '../game.dart';
import '../recipes.dart';
import '../items.dart';
import 'planner.dart';
import 'dart:math';

class Goal {
  final Map<Item, int> itemToCount;
  Goal(this.itemToCount);

  Iterable<ItemCount> get itemCounts =>
      itemToCount.entries.map((e) => ItemCount(e.key, e.value));

  bool haveMet(GameState state) {
    var inventory = state.inventory;
    var currentCounts = inventory.itemToCount;
    for (var targetCount in itemCounts) {
      var count = currentCounts[targetCount.item] ?? 0;
      if (count < targetCount.count) {
        return false;
      }
    }
    return true;
  }

  // If the goal is 2 A and 1 B, return .3 when we have 0 A and 1 B.
  double percentComplete(GameState state) {
    // For each goal, figure out what % complete in current state.
    // Return a weighted average of all the goals?
    var inventory = state.inventory;
    var currentCounts = inventory.itemToCount;
    var currentGoalItems = 0;
    var totalTargetItems = 0;
    for (var targetCount in itemCounts) {
      currentGoalItems +=
          min(currentCounts[targetCount.item] ?? 0, targetCount.count);
      totalTargetItems += targetCount.count;
    }
    return currentGoalItems / totalTargetItems;
  }

  double scoreForState(GameState state) {
    return percentComplete(state);
    // if (haveMet(state)) {
    //   return 1.0;
    // }
    // return 0.0;
  }
}

Action pickAction(List<Action> actions) {
  return actions.first;
}

Iterable<Action> actionsWithOutput(Item output) sync* {
  var recipes = recipesWithOutput(output);
  for (var recipe in recipes) {
    yield Craft(recipe: recipe);
  }
  if (output.gatherSkill != null) {
    // FIXME: Should have a specific output?
    yield SendMinion();
  }
}

class ActionNodeCache {
  final GameState state;
  final Map<ItemCount, ActionNode> _cache = {};

  ActionNodeCache(this.state);

  ActionNode actionSubtreeForItemCount(ItemCount count) {
    if (!_cache.containsKey(count)) {
      _cache[count] = _buildSubtreeForItemCount(count);
    }
    return _cache[count]!;
  }

  Iterable<ActionNode> childActionNodesForAction(Action action) {
    if (action is Craft) {
      return action.recipe.inputCounts.map(actionSubtreeForItemCount);
    } else if (action is SendMinion) {
      return [];
    } else {
      throw Exception('Unknown action: $action');
    }
  }

  // Build a tree to understand worst-case crafting time of any given item.
// Also worst-case energy and tool costs.
// Does not consider current inventory, but does consider skills.
  ActionNode _buildSubtreeForItemCount(ItemCount count) {
    // Items which come from multiple sources include bones, feathers, meat
    // which come from skinning recipes (in various amounts) and thus come from
    // hunting recipes.
    // Sticks also come from multiple recipes, as do bark, logs, leaves.
    // Can just pick the first for now?  Or pick the one with the best ratio
    // of the desired item?
    // Lots of things can come from taking other things apart.
    // Certain cooking/eating can produce shells or pots.

    // Action nodes include best/worse case for number of actions, and can also
    // be queried for how much energy cost or tool cost is needed for the subtree.

    assert(!_cache.containsKey(count));
    // e.g. Peeled banana
    // Figure out what actions produce such, pick the best one.
    // Do we need to pick one or just keep them all?
    var actions = actionsWithOutput(count.item);
    assert(actions.isNotEmpty);
    var action = pickAction(actions.toList());

    // Recurse on the inputs of the action(s).
    var children = childActionNodesForAction(action).toList();
    // Return the node linking to recursed children.
    // var bestCaseCount =
    //     (count.count / action.maxOutputCount(count.item, state.skills)).ceil();
    // // Figure out the success chance of the action.
    // var successChance = action.outputChance(count, state.skills);
    // var worstCaseCount = (bestCaseCount / successChance).ceil();
    var node = ActionNode(
      output: count,
      action: action,
      children: children,
      // bestCaseActionCount: bestCaseCount,
      // worstCaseActionCount: worstCaseCount,
    );
    return node;
  }
}

class ActionTree extends Node {
  final Goal goal;
  final GameState state;
  final ActionNodeCache _cache;

  ActionTree.build(this.state, this.goal)
      : _cache = ActionNodeCache(state),
        super.root() {
    children = goal.itemCounts.map(_cache.actionSubtreeForItemCount).toList();
  }
}

class GoalPlanner extends Planner {
  final Goal goal;
  GoalPlanner(this.goal);

  Action? nextAction(ActionNode root, Map<Item, int> itemCounts) {
    // Start at the root of the action tree and walk until we find an action
    // which needs completing.
    // Do we have the items this node is trying to generate?
    var existingCount = itemCounts[root.output.item] ?? 0;
    if (existingCount >= root.output.count) {
      // If so, then return null.
      // Do we need to remove the items from the item counts?
      // Removing only needed if we have sibling nodes for the same outputs?
      return null;
    }
    // If we're not done check if our children have work to do.
    for (var node in root.children) {
      var actionFromDecendent = nextAction(node, itemCounts);
      if (actionFromDecendent != null) {
        return actionFromDecendent;
      }
    }
    // Our decendents didn't have any actions to complete, so must be us.
    return root.action;
  }

  @override
  Action plan(GameState state) {
    // Do we need energy?  If so, eat.
    if (state.meHunger > 10 || state.minionHunger > 10) {
      // Do we have food (ideally cooked food)?

    }
    // Do we have things we can cook?
    // Do we have resources with which to cook?
    // Do we have tools with which to cook?
    // If we don't have food, gather (and skin).

    // Figure out what actions are needed to get to the goal.
    var tree = ActionTree.build(state, goal);
    // How much energy will this action tree cost?
    // Plan to fetch that much food?

    // How much tool durability will this cost?
    // If we need tools, plan an action tree to create them.

    // Action tree is only invalidated when skill state changes?
    var itemCounts = state.inventory.itemToCount;
    for (var node in tree.children) {
      var actionFromRoot = nextAction(node, itemCounts);
      if (actionFromRoot != null) {
        return actionFromRoot;
      }
    }
    throw "Goal must already have been completed if action tree is complete?";
  }
}

// Calculate the action tree needed to get a given item (ignoring inventory?)
// For things with random outcomes, need to simulate and predict outcomes?
// Calculate best-case/worst-case outcomes?  Where as worst-case is defined by
// the Xth percentile?
// ActUntil(goal) with expectation of how many?

class Node {
  late final List<ActionNode> children;

  Node(this.children);

  Node.root();

  int get subTreeMinCount =>
      children.fold(0, (sum, child) => sum + child.subTreeMinCount);
  int get subTreeMaxCount =>
      children.fold(0, (sum, child) => sum + child.subTreeMaxCount);
}

class ActionNode extends Node {
  final ItemCount output;
  final Action action;
  // int bestCaseActionCount;
  // int worstCaseActionCount; // best case / success chance

  ActionNode({
    required List<ActionNode> children,
    required this.output,
    required this.action,
    // required this.bestCaseActionCount,
    // required this.worstCaseActionCount,
  }) : super(children);
}
