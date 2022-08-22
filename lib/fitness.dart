import 'dart:math';

import 'game.dart';
import 'recipes.dart';
import 'items.dart';

// Possible fitness values:

// Total inventory Click cost?
// We don't currently keep click costs around, but given an item could work them out?

// Total inventory Time cost?
// We don't currently keep aquisition time around, but could potentially calaculate
// given an item?

// ** Total inventory Energy value?
// This will de-value non-energy things?
int totalInventoryEnergyValue(GameState state) {
  int total = 0;
  for (var item in state.inventory.uniqueItems) {
    if (item.energy != null) {
      var count = state.inventory.countOf(item);
      total += item.energy! * count;
    }
  }
  return total;
}

// ** Total skill value
double totalSkillValue(GameState state) {
  return state.skills.totalValue;
}

// ** Total inventory crafting level value?

// Should be memoized?
int minimumSkillNeededFor(Item item) {
  if (item.gatherSkill != null) {
    return item.gatherSkill!;
  }
  var recipes = recipesWithOutput(item);
  // pick the recipe which produces this output with the lowest skill level?
  var skillLevels = recipes.map((r) => r.skillRequired).toList();
  return skillLevels.reduce(min);
}

// Minimum crafting levels of all inventory items added together.
int totalInventoryCraftingLevels(GameState state) {
  int total = 0;
  for (var item in state.inventory.uniqueItems) {
    var count = state.inventory.countOf(item);
    total += minimumSkillNeededFor(item) * count;
  }
  return total;
}

// // Is this actionCount or clickCount?
// int bestCaseClickCount(Item item, int itemCount, GameState state) {
//   // If we already have N of the item already click count is 0?
//   if (state.inventory.countOf(item) >= itemCount) {
//     return 0;
//   }
//   // Otherwise best case is the needed action itemCount / output count times?
//   var recipes = recipesWithOutput(item);
//   // If we have multiple possible recipes it needs to recurse.
//   var bestClickCount = 0;
//   for (var recipe in recipes) {
//     var count = 0;
//     for (var entry in recipe.inputs.entries) {
//       count += bestCaseClickCount(entry.key, entry.value, state);
//     }
//     var clickCount = (count / recipe.outputCount(item)).ceil();
//     if (count < bestClickCount) {
//       bestClickCount = clickCount;
//     }
//   }
//   return bestClickCount;
// }

// // Is this actionCount or clickCount?
// int worstCaseClickCount(Item item, int itemCount, GameState state) {
//   // If we already have N of the item, click count is 0?
//   if (state.inventory.countOf(item) >= itemCount) {
//     return 0;
//   }
//   // Figure out what % chance we have to pull item at each try?
//   // Otherwise worst case is how many actions are needed to get to XX% chance?
// }

// Cost to get one more, given current inventory and skills.
int clickCostForItem(Item item, GameState state) {
  throw UnimplementedError();
}

// How to handle multiples?
// Do we cache each avaiable recipe?  Do we also cache the click/output ratio?
