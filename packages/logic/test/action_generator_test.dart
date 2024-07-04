import 'package:dash_craft/doc.dart';
import 'package:dash_craft/game.dart';
import 'package:dash_craft/plan/planner.dart';
import 'package:test/test.dart';

void main() {
  test('possibleCrafts', () {
    final doc = DOC.load();
    final actionGenerator = ActionGenerator(doc);
    final inventory = Inventory.fromItems([doc.banana]);
    const skills = Skills({Skill.foodPrep: 0});
    final actions = actionGenerator.possibleCrafts(inventory, skills);
    expect(actions.length, 1);
    expect(actions.first.recipe.outputs[doc.peeledBanana], 1);
  });
}
