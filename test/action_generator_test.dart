import 'package:dash_craft/game.dart';
import 'package:dash_craft/items.dart';
import 'package:test/test.dart';
import 'package:dash_craft/plan/planner.dart';

void main() {
  test('possibleCrafts', () {
    var inventory = const Inventory(items: [banana]);
    var skills = const Skills({Skill.foodPrep: 0});
    var actions = ActionGenerator.possibleCrafts(inventory, skills);
    expect(actions.length, 1);
    expect(actions.first.recipe.outputs[peeledBanana], 1);
  });
}
