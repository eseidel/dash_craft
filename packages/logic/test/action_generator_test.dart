import 'package:logic/doc.dart';
import 'package:logic/game.dart';
import 'package:logic/plan/planner.dart';
import 'package:test/test.dart';

void main() {
  test('possibleCrafts', () {
    final doc = DOC.load();
    final actionGenerator = ActionGenerator(doc);
    final inventory = Inventory.fromItems([doc.banana]);
    const skills = Skills({Skill.mealPreparing: 0});
    final actions = actionGenerator.possibleCrafts(inventory, skills);
    expect(actions.length, 1);
    expect(actions.first.recipe.outputs[doc.peeledBanana], 1);
  });
}
