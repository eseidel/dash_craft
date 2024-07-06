import 'package:logic/rules.dart';
import 'package:test/test.dart';

void main() {
  final doc = DOC.load();
  final cookbook = Cookbook(doc.recipes);
  final banana = doc.banana;
  final peeledBanana = doc.peeledBanana;

  test('cookbook', () {
    final result = cookbook
        .findRecipe(CraftingBench.fromStacks([ItemStack(type: banana)]));
    expect(result, isNotNull);
    expect(result!.count, 1);
    expect(result.recipe.outputAsList, [peeledBanana]);
  });

  test('multiple craft', () {
    final result = cookbook.findRecipe(
      CraftingBench.fromStacks([ItemStack(type: banana, count: 2)]),
    );
    expect(result, isNotNull);
    expect(result!.count, 2);
    expect(result.recipe.outputAsList, [peeledBanana]);
  });
}
