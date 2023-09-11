import 'dart:math';

import 'package:dash_craft/game.dart';
import 'package:dash_craft/items.dart';
import 'package:dash_craft/recipes.dart';
import 'package:meta/meta.dart';

// Actions types
// craft (use current tool, click craft)
// Send minion (click minion)
// Feed minion/me (drag pile onto)
// Burn (drag pile onto fire)
// discard (drag pile onto trash)
// equip (drag item onto slot)

class ActionResult {
  const ActionResult({
    required this.action,
    required this.timeInMilliseconds,
    this.addItems = const [],
    this.removeItems = const [],
    this.meEnergyChange = 0,
    this.minionEnergyChange = 0,
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
  // Inventory changes
  // skill changes
  final Action action;
  final List<Item> addItems;
  final List<Item> removeItems;
  final int timeInMilliseconds;
  final Skills skillChange;

  final int meEnergyChange;
  final int minionEnergyChange;

  @override
  String toString() {
    final values = <String>[];
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
  ResolveContext(this.state, this.random);
  final Random random;
  final GameState state;

  Skills get skills => state.skills;

  Skills? gatherSkillChange(Item item) {
    final skillDiff = skills[Skill.gather] - item.gatherSkill!;
    if (skillDiff >= 40) {
      return null;
    }
    // This gets us something between 0.1 and 0.5, bigger when less skilled.
    final change = min(1.0 - (skillDiff / 40) * 0.5, 0.1);
    return Skills({Skill.gather: change});
  }

  Skills? craftingSkillChange(Recipe recipe) {
    final skillDiff = skills[recipe.skill] - recipe.skillRequired;
    if (skillDiff >= 40) {
      return null;
    }
    // This gets us something between 0.1 and 0.5, bigger when less skilled.
    final change = min(1.0 - (skillDiff / 40) * 0.5, 0.1);
    return Skills({recipe.skill: change});
  }

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
  double outputChance(ItemCount count, Skills skills) => 0;

  @override
  bool validate(GameState state) => true;
  @override
  ActionResult resolve(ResolveContext context) => const ActionResult.empty();
}

class Craft extends Action {
  const Craft({required this.recipe});
  final Recipe recipe;
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
      return 0;
    }
    return successChance(skills);
  }

  double successChance(Skills skills) {
    return 0.5;
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
        skillChange: context.craftingSkillChange(recipe),
      );
    }
    // Learn about the recipe requirements if necessary
    // If learned, show recipe on screen.
  }

  @override
  String toString() => 'Craft($recipe)';
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
    // TODO(eseidel): Some gathers should return multiple items.
    if (count.count != 1) return 0;

    final availableItems = availableGatherItems(skills);
    if (!availableItems.contains(count.item)) return 0;
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

  Iterable<Item> availableGatherItems(Skills skills) {
    return gatherItems.where((i) {
      return i.gatherSkill != null && i.gatherSkill! <= skills[Skill.gather];
    });
  }

  int gatherTimeMs(ResolveContext context) {
    if (context.state.minionEnergy < 1) {
      return 1000;
    }
    return 100;
  }

  ActionResult gatherResult(ResolveContext context) {
    final items = availableGatherItems(context.skills);
    final item = context.pickOne(items.toList());

    final addItems = [item];
    // Half the time give double?
    if (context.nextDouble() < 0.5) {
      addItems.add(item);
    }

    return ActionResult(
      action: this,
      addItems: addItems,
      timeInMilliseconds: gatherTimeMs(context),
      skillChange: context.gatherSkillChange(item),
      minionEnergyChange: -1,
    );
  }

  @override
  ActionResult resolve(ResolveContext context) {
    switch (task) {
      case MinionTask.gather:
        return gatherResult(context);
      case MinionTask.lumberjack:
      case MinionTask.hunt:
      case MinionTask.fish:
      case MinionTask.treasureHunt:
        throw UnimplementedError();
    }
  }

  @override
  String toString() {
    return 'SendMinion(${task.name})';
  }
}

enum TargetHuman {
  me,
  minion,
}

class Feed extends Action {
  const Feed({required this.inputs, required this.target});
  // inputs
  final List<Item> inputs;
  final TargetHuman target;

  @override
  int maxOutputCount(Item item, Skills skills) {
    // TODO(eseidel): Handle eating things in shells, pots, etc.
    return 0;
  }

  @override
  double outputChance(ItemCount count, Skills skills) {
    // This also needs to handle output chance for shells, pots, etc.
    return 0;
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
    final totalEnergy = inputs
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
