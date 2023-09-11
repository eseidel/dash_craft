import 'package:meta/meta.dart';

enum ItemKind {
  other,
  food,
  tool,
}

@immutable
class Item {
  const Item.other({
    required this.name,
    this.energy,
    this.gatherSkill,
  })  : durability = 0,
        toolLevel = null,
        kind = ItemKind.other;

  const Item.food({required this.name, required this.energy, this.gatherSkill})
      : durability = 0,
        toolLevel = null,
        kind = ItemKind.food;
  const Item.tool({
    required this.name,
    required this.durability,
    this.gatherSkill,
    this.toolLevel,
  })  : energy = null,
        kind = ItemKind.tool;
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
  final int durability;
  final int? energy;
  final int? gatherSkill;
  final int? toolLevel;

  @override
  String toString() => name;
}

// This should be yaml.
const banana = Item.food(name: 'Banana', energy: 1, gatherSkill: 0);
const orange = Item.food(name: 'Orange', energy: 1, gatherSkill: 0);
const coconut = Item.other(name: 'Coconut', gatherSkill: 5);
const stone =
    Item.tool(name: 'Stone', durability: 5, toolLevel: 1, gatherSkill: 10);

const peanut = Item.food(name: 'Peanut', energy: 1, gatherSkill: 15);
const blueberry = Item.food(name: 'Blue Berry', energy: 1, gatherSkill: 20);
const redberry = Item.food(name: 'Red Berry', energy: 1, gatherSkill: 20);
const vine = Item.other(name: 'Vine', gatherSkill: 25);
const stick = Item.other(name: 'Stick', gatherSkill: 25);
const walnut = Item.food(name: 'Walnut', energy: -2, gatherSkill: 30);
const chestnut = Item.food(name: 'Chestnut', energy: -2, gatherSkill: 30);
const lettuce = Item.food(name: 'Lettuce', energy: 2, gatherSkill: 35);
const tomato = Item.food(name: 'Tomato', energy: 2, gatherSkill: 35);
const carrot = Item.food(name: 'Carrot', energy: 2, gatherSkill: 45);
const eggplant = Item.food(name: 'Eggplant', energy: 2, gatherSkill: 50);
const apple = Item.food(name: 'Apple', energy: 2, gatherSkill: 55);
const potato = Item.food(name: 'Potato', energy: 2, gatherSkill: 60);

List<Item> gatherItems = const [
  banana,
  orange,
  coconut,
  stone,
  peanut,
  blueberry,
  redberry,
  vine,
  stick,
  walnut,
  chestnut,
  lettuce,
  tomato,
  carrot,
  eggplant,
  apple,
  potato,
];

const goop = Item.food(name: 'Goop', energy: -1);

// Are these the same as recipes?
const peeledBanana = Item.food(name: 'Peeled Banana', energy: 3);
const peeledOrange = Item.food(name: 'Peeled Orange', energy: 3);
const walnutKernel = Item.food(name: 'Walnut Kernel', energy: 4);
const slicedBanana = Item.food(name: 'Sliced Banana', energy: 8);
const peanutKernel = Item.food(name: 'Peanut Kernel', energy: 5);
const openedCoconut = Item.food(name: 'Opened Coconut', energy: 2);
const rawCoconut = Item.food(name: 'Raw Coconut', energy: 8);
const mixedBerries = Item.food(name: 'Mixed Berries', energy: 5);
const chestnutKernel = Item.food(name: 'Chestnut Kernel', energy: 4);
const blueBerryMash = Item.food(name: 'Blue Berry Mash', energy: 8);
const redBerryMash = Item.food(name: 'Red Berry Mash', energy: 8);
const mixedBerryMash = Item.food(name: 'Mixed Berry Mash', energy: 15);
const bananaMash = Item.food(name: 'Banana Mash', energy: 12);
const slicedOrange = Item.food(name: 'Sliced Orange', energy: 6);
const slicedTomato = Item.food(name: 'Sliced Tomato', energy: 8);
const slicedCarrot = Item.food(name: 'Sliced Carrot', energy: 8);
const cutLettuce = Item.food(name: 'Cut Lettuce', energy: 7);
const slicedEggplant = Item.food(name: 'Sliced Eggplant', energy: 9);
const slicedPotato = Item.food(name: 'Sliced Potato', energy: 10);
const slicedApple = Item.food(name: 'Sliced Apple', energy: 10);

const cookedRedMeat = Item.food(name: 'Cooked Red Meat', energy: 13);

// Can't be eaten, but can be burned with energy 2.
const coconutShell = Item.other(name: 'Coconut Shell');

const sharpStone = Item.tool(name: 'Sharp Stone', durability: 5);
const primativeAxe = Item.tool(name: 'Primative Axe', durability: 15);
const primativeHammer = Item.tool(name: 'Primative Hammer', durability: 15);
const primativeKnife = Item.tool(name: 'Primative Knife', durability: 15);


// Primitive axe.png	Primitive Axe	Sharp Stone	Vine	Stick	Hand	0		15		1	
// Primitive hammer.png	Primitive Hammer	Stone	Vine	Stick	Hand	5		15		1	
// Primitive knife.png	Primitive Knife	Sharp Stone	Stick		Stone	5		15	2	1	
// Stone Axe Head.png	Stone Axe Head	Stone			Sharp Stone	10		10	1		
// Vine Rope.png	Vine Rope	Vine x2			Hand	10	1			2	
// Stone Axe	Stone Axe Head	Stick		Stone	10					
// Primitive Spear	Sharp Stone	Vine Rope	Stick	Hand	15		15	3	1	
// Small Fire	Stick	Bark Strips		Hand	15		1		5	
// Camp Fire	Stick x10	Stone x10		Small Fire	15				10	Max Heat: 1000
// Sling	Light Fur	Bark Strips x5		Hand	20			4	1	
// Bone Hook	Bone			Primitive Knife	20					
// Primitive Fishing Rod	Bone Hook	Vine Rope		Hand	30					Max Bait: 25
// Bonfire	Stick x20	Stone x20		Small Fire	25				20	Max Heat: 2000
// Arrow	Bone	Stick	Feather	Stone	30					
// Basic hammer.png	Basic hammer	Stick	Vine Rope	Stone	Primitive Hammer	35					
// Basic Knife	Stick	Vine Rope	Sharp Stone	Primitive Hammer	35			3		
// Bark Rope	Bark Strips x2			Hand	35					
// Wooden Fishing Rod	Primitive Fishing Rod	Stick	Worm	Hand	40					Max Bait: 50
// Primitive Claw	Sharp Stone x2	Stick	Vine	Hand	45	5	15		1	
// Sharp Bone	Bone			Primitive Hammer	45	5	15	2		
// Sharp Shiny Stone	Shiny Stone			Basic hammer	50		100	3		
// Advanced Hammer	Peeled Stick	Vine Rope	Stone	Hammer	55	10	50			
// Advanced Axe	Peeled Stick	Axe Head		Hammer	55	10	50			
// Advanced Spear	Sharp Bone	Peeled Stick	Vine Rope	Hand	55	10	50	5		
// Advanced Knife	Peeled Stick	Vine Rope	Sharp Bone	Hammer	55	10	50	4		
// Advanced Fishing Rod	Primitive Fishing Rod	Stick	Fish Meat	Hand	55					Max Bait: 100
// Stacked Bone	Bone x10	Bark Rope x2		Hand	60					
// Brush	Peeled Stick	Bark Rope	Feather x10	Hand	60		1		1	
// Kiln	Stick x20	Mud Brick x20		Small Fire	60					Max Heat: 3000
// Trowel Head	Sharp Stone			Hammer	60					
// Colored Brush	Red Berry x5	Lettuce x5	Blue Berry x5	Brush	65	10	25		1	
// Basic Trowel	Trowel Head	Vine	Stick	Hammer	65		25		1	
// Basic Claw	Sharp Stone x2	Stick	Vine Rope	Hammer	65		25		1	
// Basic Torch	Stick	Light Fur	Charcoal	Fire	65					
// Epic Fishing Rod	Primitive Fishing Rod	Peeled Stick	Fish Meat	Hand	70					Max Bait: 200
// Epic Axe	Peeled Stick	Bark Rope	Axe Head	Hammer	70					
// Epic Hammer	Peeled Stick	Bark Rope	Stone	Hammer	70					
// Epic Knife	Peeled Stick	Bark Rope	Sharp Bone	Hammer	70			5		
// Epic Spear	Sharp Bone	Peeled Stick	Bark Rope	Hand	70			6		
// Furnace	Stone x80	Mud Brick x80		Small Fire	80					Max Heat: 5000
// Advanced Trowel	Trowel Head	Vine Rope	Peeled Stick	Basic hammer	80					
// Advanced Claw	Sharp Stone x2	Peeled Stick	Vine Rope	Primitive Hammer	80					
// Epic Claw	Sharp Stone x2	Peeled Stick	Bark Rope	Basic hammer	85					
// Epic Trowel	Trowel Head	Bark Rope	Peeled Stick	Advanced Hammer	90					
// Tactical Tool	Peeled Stick	Bark Rope x3	Stone x6	Epic Hammer	100		100			
// Tactical Shiny Tool	Peeled Stick	Bark Rope x3	Shiny Stone x6	Epic Hammer	120		1000		1	
