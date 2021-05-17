import 'dart:math';

// This should be yaml.
class ItemType {
  String name;
  // Is everything allowed to stack?
  // Are things which can't stack just 1 offs?
  int maxStackSize = 100;
  ItemType({required this.name});
}

ItemType banana = ItemType(name: 'Banana');
ItemType stone = ItemType(name: 'Stone');

class ItemStack {
  final ItemType type;
  int count;
  ItemStack({required this.type, this.count = 1});

  void takeFrom(ItemStack from) {
    if (from.type != type) {
      throw ArgumentError('Can\'t add non-matching item type.');
    }
    int spaceLeft = type.maxStackSize - count;
    int taking = min(from.count, spaceLeft);
    count += taking;
    from.count -= taking;
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
