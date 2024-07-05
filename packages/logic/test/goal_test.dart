import 'package:logic/game.dart';
import 'package:logic/plan/goal.dart';
import 'package:logic/src/items.dart';
import 'package:test/test.dart';

void main() {
  test('percentComplete', () {
    const empty = GameState.empty();
    const stone = Item(name: 'Stone');
    const banana = Item(name: 'Banana');
    final goal = Goal({stone: 100});
    expect(goal.percentComplete(empty), 0);

    final one = empty.copyWith(
      inventory: Inventory.fromCounts(const {stone: 1, banana: 20}),
    );
    expect(goal.percentComplete(one), 0.01);

    final hundred = empty.copyWith(
      inventory: Inventory.fromCounts(const {stone: 100, banana: 200}),
    );
    expect(goal.percentComplete(hundred), 1);

    final half = empty.copyWith(
      inventory: Inventory.fromCounts(const {stone: 50, banana: 50}),
    );
    expect(goal.percentComplete(half), 0.5);

    final goal2 = Goal({stone: 1, banana: 3});
    final quarter = empty.copyWith(
      inventory: Inventory.fromCounts(const {stone: 0, banana: 1}),
    );
    expect(goal2.percentComplete(quarter), 0.25);
  });
}
