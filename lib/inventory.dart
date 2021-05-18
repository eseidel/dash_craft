import 'dart:math';

// This should be yaml.
class ItemType {
  String name;
  // Is everything allowed to stack?
  // Are things which can't stack just 1 offs?
  int maxStackSize = 100;
  int energy;
  ItemType({required this.name, this.energy = 0});
}

ItemType banana = ItemType(name: 'Banana', energy: 1);
ItemType peeledBanana = ItemType(name: 'Peeled Banana', energy: 3);
ItemType stone = ItemType(name: 'Stone');
ItemType cookedRedMeat = ItemType(name: 'Cooked Red Meat', energy: 13);

class ItemStack {
  final ItemType type;
  int count;
  ItemStack({required this.type, this.count = 1});

  int get energy => type.energy * count;
  int get spaceLeft => type.maxStackSize - count;

  void takeFrom(ItemStack from, {int limit = 100}) {
    if (from.type != type) {
      throw ArgumentError('Can\'t add non-matching item type.');
    }
    int maxCouldTake = min(from.count, spaceLeft);
    int taking = min(maxCouldTake, limit);
    count += taking;
    from.count -= taking;
  }

  bool haveSpaceFor(ItemStack from) {
    if (from.type != type) return false;
    return spaceLeft >= from.count;
  }

  // Not sure this is safe.
  ItemStack takeOneAsNewStack() {
    assert(count > 1);
    count -= 1;
    // Also copy durability!
    return ItemStack(type: type, count: 1);
  }
}

class ItemContainer {
  final int capacity;
  final List<ItemStack> _itemStacks = [];

  ItemContainer({required this.capacity});

  bool tryAdd(ItemStack toAdd) {
    // Go through each stack.
    // If we already have one of type add to that stack.
    for (var stack in _itemStacks) {
      if (stack.type == toAdd.type) {
        stack.takeFrom(toAdd);
        if (toAdd.count == 0) continue;
      }
    }
    // Items of equally reduced durability should be able to stack together.
    if (toAdd.count > 0 && _itemStacks.length < capacity) {
      _itemStacks.add(toAdd);
    }

    return toAdd.count == 0;
  }
}

class Inventory extends ItemContainer {
  Inventory() : super(capacity: 25);

  ItemStack? stackAt(int index) {
    if (index < _itemStacks.length) return _itemStacks[index];
    return null;
  }
}
