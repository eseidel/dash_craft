import 'package:dash_craft/game.dart';
import 'package:dash_craft/items.dart';
import 'package:dash_craft/plan/goal.dart';
import 'package:test/test.dart';

void main() {
  test('percentComplete', () {
    const empty = GameState.empty();
    final goal = Goal({stone: 100});
    expect(goal.percentComplete(empty), 0);

    final one = empty.copyWith(
      inventory: const Inventory.fromCounts({stone: 1, banana: 20}),
    );
    expect(goal.percentComplete(one), 0.01);

    final hundred = empty.copyWith(
      inventory: const Inventory.fromCounts({stone: 100, banana: 200}),
    );
    expect(goal.percentComplete(hundred), 1);

    final half = empty.copyWith(
      inventory: const Inventory.fromCounts({stone: 50, banana: 50}),
    );
    expect(goal.percentComplete(half), 0.5);

    final goal2 = Goal({stone: 1, banana: 3});
    final quarter = empty.copyWith(
      inventory: const Inventory.fromCounts({stone: 0, banana: 1}),
    );
    expect(goal2.percentComplete(quarter), 0.25);
  });
}
