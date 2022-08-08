import 'package:meta/meta.dart';

enum ItemKind {
  food,
  tool,
}

@immutable
class Item {
  // name
  // is tool
  // max durability
  // recipe
  // max stack size
  // energy (burn, eat, use?)
  final String name;
  final ItemKind kind;
  // Is everything allowed to stack?
  // Are things which can't stack just 1 offs?
  final int stackSize = 100;
  final int durability;
  final int energy;
  const Item.food({required this.name, required this.energy})
      : durability = 0,
        kind = ItemKind.food;
  const Item.tool({required this.name, required this.durability})
      : energy = 0,
        kind = ItemKind.tool;
}

// This should be yaml.
const banana = Item.food(name: 'Banana', energy: 1);
const goop = Item.food(name: 'Goop', energy: -1);
const peeledBanana = Item.food(name: 'Peeled Banana', energy: 3);
const orange = Item.food(name: 'Orange', energy: 1);
const peeledOrange = Item.food(name: 'Peeled Orange', energy: 3);
const stone = Item.tool(name: 'Stone', durability: 5);
const walnut = Item.food(name: 'Walnut', energy: -2);
const cookedRedMeat = Item.food(name: 'Cooked Red Meat', energy: 13);
