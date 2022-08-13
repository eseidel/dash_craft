import 'game.dart';
import 'action.dart';
import 'items.dart';
import 'inventory.dart';

import 'dart:math';

class Goal {
  final Map<Item, int> itemToCount;
  Goal(this.itemToCount);

  Iterable<ItemCount> get itemCounts =>
      itemToCount.entries.map((e) => ItemCount(e.key, e.value));

  bool haveMet(GameState state) {
    var inventory = state.inventory;
    var currentCounts = inventory.asMap();
    for (var targetCount in itemCounts) {
      var count = currentCounts[targetCount.item] ?? 0;
      if (count < targetCount.count) {
        return false;
      }
    }
    return true;
  }
}

// Mutable, does planning.
// Input a goal.
// Output is successive actions to achieve the goal.
abstract class Planner {
  Iterable<Craft> possibleCrafts(Inventory inventory, Skills skills) sync* {
    var counts = inventory.asMap();
    for (var recipe in recipes) {
      if (recipe.skillLevel <= skills[recipe.skill] &&
          recipe.inputs.entries.every(
              (e) => counts[e.key] != null && counts[e.key]! >= e.value)) {
        yield Craft(recipe: recipe);
      }
    }
  }

  List<SendMinion> possibleSendMinions(Inventory inventory) {
    // TODO: Other send types depending on available items.
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

  Action plan(GameState state);
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

double fitnessFunction(GameState state) {
  double fitness = 0.0;

  fitness += state.skills.totalPercent;
  // fitness += state.totalEnergyPercent;
  // fitness += state.inventorySizePercent;
  // Inventory
  // Tool power levels
  // fitness += state.inventory.availableToolPowerLevelsPercent;
  // // Tool durability levels
  // fitness += state.inventory.toolDurabilityPercent;
  // Food energy
  // Burn energy
  // existance of various tools?
  // total number of items (up to a point)?
  return fitness;
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
    var itemCounts = state.inventory.asMap();
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
