import 'package:flutter/cupertino.dart';

import 'inventory.dart';
import 'dart:math';
import 'items.dart';

class GameState extends ChangeNotifier {
  CraftingInputs craftingInputs = CraftingInputs();
  Inventory inventory = Inventory();
  Skills skills = Skills();
  Human me = Human();
  Human minion = Human();
  Cookbook cookbook = Cookbook();

  void Function(String message)? showMessageHandler;

  GameState(this.showMessageHandler);

  void showMessage(String message) {
    if (showMessageHandler != null) {
      showMessageHandler!(message);
    }
  }

  void eatFood({required ItemStack from, required Human to}) {
    // Reject non-food items?
    if (from.energy == 0) {
      showMessage("Can't eat that!");
      return;
    }
    assert(from.energy > 0); // Eventually not required.
    int missing = to.missingEnergy;
    int canTake = missing ~/ from.type.energy;
    if (canTake == 0) {
      // Not even one would fit.
      showMessage("Already full.");
      return;
    }
    int willTake = min(canTake, from.count);
    from.count -= willTake;
    to.energy += willTake * from.type.energy;
    notifyListeners();
  }

  // void itemWellTap({required ItemStack stack, required DragLocation location}) {
  //   assert(stack.count > 0);
  //   if (location != DragLocation.inventory) return; // Temporary.

  //   bool success = craftingInputs.addOneFrom(stack);
  //   if (!success) {
  //     showMessage('Crafting table full');
  //     return;
  //   }
  //   notifyListeners();
  // }

  // void fetchPressed() {
  //   inventory.tryAdd(fetcher.gather());
  //   notifyListeners();
  // }

  // Drag types
  // Inventory -> Human (destroy stack, change to energy)
  // Crafting Table -> Inventory (move stack, add in position)
  // Inventory -> Slot -> (move to slot)
  // Inventory -> Container -> Add to list
  // Inventory -> Fire -> (destroy stack, change to fuel)
  // Inventory -> Quiver/Rod -> (destroy stack, change to fuel)

  double successChance(RecipeLookup recipe, Skills skills) {
    return 0.5;
  }

  void craftPressed() {
    // Check if valid recipe
    var recipeResult = cookbook.findRecipe(craftingInputs);
    // Multipler for recipe?
    if (recipeResult == null) {
      showMessage('No such recipe');
      // Is there still learning?
      return;
    }
    // Check space in inventory.
    // Check tool durability.
    // Check tool level.
    // Learn about the recipe requirements if necessary
    // Take items
    craftingInputs.clear();
    // Check success percent.
    bool successful =
        Random().nextDouble() < successChance(recipeResult, skills);
    // If successful, add results to inventory.
    ItemStack? toAdd;
    if (successful) {
      // Handle multiple outputs.
      toAdd = ItemStack(
          type: recipeResult.recipe.outputs.first, count: recipeResult.count);
    } else {
      showMessage('Crafting failed!');
      // Do learning
      // If learned, show recipe on screen.
      // If was food, give goop!
      // Does goop come in multiples?
      if (recipeResult.recipe.failureGivesGoop) {
        toAdd = ItemStack(type: goop);
      }
    }
    if (toAdd != null) inventory.tryAdd(toAdd);

    // Refill slots if needed.
    notifyListeners();
  }
}
