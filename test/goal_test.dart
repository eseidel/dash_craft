import 'package:dash_craft/game.dart';
import 'package:dash_craft/items.dart';
import 'package:test/test.dart';
import 'package:dash_craft/plan/goal.dart';

void main() {
  test('percentComplete', () {
    var empty = const GameState.empty();
    var goal = Goal({stone: 100});
    expect(goal.percentComplete(empty), 0);

    var one = empty.copyWith(
        inventory: const Inventory.fromCounts({stone: 1, banana: 20}));
    expect(goal.percentComplete(one), 0.01);

    var hundred = empty.copyWith(
        inventory: const Inventory.fromCounts({stone: 100, banana: 200}));
    expect(goal.percentComplete(hundred), 1);

    var half = empty.copyWith(
        inventory: const Inventory.fromCounts({stone: 50, banana: 50}));
    expect(goal.percentComplete(half), 0.5);

    var goal2 = Goal({stone: 1, banana: 3});
    var quarter = empty.copyWith(
        inventory: const Inventory.fromCounts({stone: 0, banana: 1}));
    expect(goal2.percentComplete(quarter), 0.25);
  });
}
