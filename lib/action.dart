import 'package:meta/meta.dart';
import 'dart:math';

import 'items.dart';
import 'game.dart';
import 'inventory.dart';

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

  int maxOutputCount(Item item, Skills skills);
  double outputChance(ItemCount count, Skills skills);

  bool validate(GameState state);

  ActionResult resolve(ResolveContext context);
}

class DummyAction extends Action {
  const DummyAction();

  @override
  int maxOutputCount(Item item, Skills skills) => 0;
  @override
  double outputChance(ItemCount count, Skills skills) => 0.0;

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

  @override
  int maxOutputCount(Item item, Skills skills) {
    if (skills[recipe.skill] < recipe.skillRequired) {
      return 0;
    }
    return recipe.outputCount(item);
  }

  @override
  double outputChance(ItemCount count, Skills skills) {
    if (recipe.outputCount(count.item) < count.count) {
      return 0.0;
    }
    return successChance(skills);
  }

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
        addItems: recipe.outputAsList,
        removeItems: recipe.inputAsList,
      );
    } else {
      // Does goop come in multiples?  How much?
      return ActionResult(
        action: this,
        timeInMilliseconds: craftTimeMs(context.skills),
        removeItems: recipe.inputAsList,
        addItems: recipe.failureGivesGoop ? [goop] : [],
        skillChange: Skills({Skill.foodPrep: learningRate(context.skills)}),
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

  @override
  int maxOutputCount(Item item, Skills skills) {
    return availableGatherItems(skills).contains(item) ? 1 : 0;
  }

  @override
  double outputChance(ItemCount count, Skills skills) {
    // FIXME: Some gathers should return multiple items.
    if (count.count != 1) return 0.0;

    var availableItems = availableGatherItems(skills);
    if (!availableItems.contains(count.item)) return 0.0;
    return 1.0 / availableItems.length;
  }

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

  Iterable<Item> availableGatherItems(Skills skills) => gatherItems.where((i) =>
      i.gatherSkill != null ? i.gatherSkill! <= skills[Skill.gather] : false);

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
      skillChange: const Skills({Skill.gather: 0.1}),
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
  int maxOutputCount(Item item, Skills skills) {
    // FIXME: Handle eating things in shells, pots, etc.
    return 0;
  }

  @override
  double outputChance(ItemCount count, Skills skills) {
    // This also needs to handle output chance for shells, pots, etc.
    return 0.0;
  }

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
