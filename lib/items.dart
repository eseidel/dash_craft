// This should be yaml.

enum ItemClass {
  food,
  tool,
}

class ItemType {
  final String name;
  final ItemClass type;
  // Is everything allowed to stack?
  // Are things which can't stack just 1 offs?
  final int maxStackSize = 100;
  final int durability;
  final int energy;
  const ItemType.food({required this.name, required this.energy})
      : durability = 0,
        type = ItemClass.food;
  const ItemType.tool({required this.name, required this.durability})
      : energy = 0,
        type = ItemClass.tool;
}

const banana = ItemType.food(name: 'Banana', energy: 1);
const goop = ItemType.food(name: 'Goop', energy: -1);
const peeledBanana = ItemType.food(name: 'Peeled Banana', energy: 3);
const orange = ItemType.food(name: 'Orange', energy: 1);
const peeledOrange = ItemType.food(name: 'Peeled Orange', energy: 3);
const stone = ItemType.tool(name: 'Stone', durability: 5);
const walnut = ItemType.food(name: 'Walnut', energy: -2);
const cookedRedMeat = ItemType.food(name: 'Cooked Red Meat', energy: 13);
