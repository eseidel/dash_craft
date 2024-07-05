import 'package:logic/game.dart';
import 'package:logic/plan/planner.dart';
import 'package:logic/rules.dart';
import 'package:test/test.dart';

void main() {
  test('possibleCrafts', () {
    final doc = DOC.load();
    final actionGenerator = ActionGenerator(doc);
    final inventory = Inventory.fromCounts({doc.banana: 1});
    const skills = Skills({Skill.mealPreparing: 0});
    final actions = actionGenerator.possibleCrafts(inventory, skills);
    expect(actions.length, 1);
    expect(actions.first.recipe.outputs[doc.peeledBanana], 1);
  });
}
