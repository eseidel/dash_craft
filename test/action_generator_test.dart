import 'package:dash_craft/game.dart';
import 'package:dash_craft/items.dart';
import 'package:dash_craft/plan/planner.dart';
import 'package:test/test.dart';

void main() {
  test('possibleCrafts', () {
    final inventory = Inventory.fromItems(const [banana]);
    const skills = Skills({Skill.foodPrep: 0});
    final actions = ActionGenerator.possibleCrafts(inventory, skills);
    expect(actions.length, 1);
    expect(actions.first.recipe.outputs[peeledBanana], 1);
  });
}
