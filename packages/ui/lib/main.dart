import 'package:flutter/material.dart';

const inputSize = 3;
const inventorySize = 25;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dash Craft',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dash Craft'),
    );
  }
}

// MVP
// Gather
// Inventory (click to destroy?)

// No:
// Gather delay
// Stacks
// Energy
// No drag and drop
// No ordering?

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum Item {
  banana,
  peeledBanana,
}

class Recipe {
  const Recipe({
    required this.name,
    required this.inputs,
    required this.outputs,
  });

  final String name;
  final List<Item> inputs;
  final List<Item> outputs;
}

const peelBanana = Recipe(
  name: 'Peel Banana',
  inputs: [Item.banana],
  outputs: [Item.peeledBanana],
);

class TappableItem extends StatelessWidget {
  const TappableItem({required this.item, required this.onTap, super.key});

  final Item? item;
  final void Function(Item) onTap;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return ItemWidget(item: item);
    }
    return GestureDetector(
      child: ItemWidget(item: item),
      onTap: () => onTap.call(item!),
    );
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({required this.item, super.key});

  final Item? item;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return const SizedBox();
    }
    return Container(
      width: 100,
      height: 100,
      color: Colors.deepPurple,
      child: Text(item.toString()),
    );
  }
}

class InputTray extends StatelessWidget {
  const InputTray({required this.items, required this.onTap, super.key});

  final List<Item> items;
  final void Function(Item) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.deepPurple,
      child: Row(
        children: [0, 1, 2].map((index) {
          final item = items.length > index ? items[index] : null;
          return TappableItem(item: item, onTap: onTap);
        }).toList(),
      ),
    );
  }
}

class CraftingBench extends StatelessWidget {
  const CraftingBench({
    required this.inputs,
    required this.onCraft,
    required this.onInputTap,
    this.recipe,
    super.key,
  });

  final List<Item> inputs;
  final Recipe? recipe;
  final void Function(Item) onInputTap;
  final void Function(List<Item> inputs) onCraft;

  @override
  Widget build(BuildContext context) {
    final recipeName = recipe?.name ?? '?';
    return Row(
      children: [
        InputTray(items: inputs, onTap: onInputTap),
        Text(recipeName),
        ElevatedButton(
          onPressed: () => onCraft(inputs),
          child: const Text('Craft'),
        ),
      ],
    );
  }
}

class InventoryGrid extends StatelessWidget {
  const InventoryGrid({
    required this.inventory,
    required this.onTap,
    super.key,
  });

  final List<Item> inventory;
  final void Function(Item) onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        itemCount: 25,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemBuilder: (BuildContext ctx, index) {
          final item = inventory.length > index ? inventory[index] : null;
          return TappableItem(item: item, onTap: onTap);
        },
      ),
    );
  }
}

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({required this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return const SizedBox();
    }
    return Text(message!);
  }
}

Recipe? recipeFor(List<Item> items) {
  if (items.length != 1) {
    return null;
  }
  if (items[0] == Item.banana) {
    return peelBanana;
  }
  return null;
}

class _MyHomePageState extends State<MyHomePage> {
  final inputs = <Item>[];
  final inventory = <Item>[];
  String? errorMessage;

  void onGather() {
    setState(() {
      inventory.add(Item.banana);
    });
  }

  void onInventoryTap(Item item) {
    if (inputs.length >= inputSize) {
      setState(() {
        errorMessage = 'Input tray is full';
      });
      return;
    }
    setState(() {
      inventory.remove(item);
      inputs.add(item);
    });
  }

  void onInputTap(Item item) {
    if (inventory.length >= inventorySize) {
      setState(() {
        errorMessage = 'Inventory full';
      });
      return;
    }
    setState(() {
      inputs.remove(item);
      inventory.add(item);
    });
  }

  void onCraft(List<Item> inputs) {
    final recipe = recipeFor(inputs);
    if (recipe == null) {
      setState(() {
        errorMessage = 'No recipe found';
      });
      return;
    }
    setState(() {
      inputs.clear();
      inventory.addAll(recipe.outputs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: onGather, child: const Text('Gather')),
            ErrorMessage(message: errorMessage),
            Expanded(
              child: CraftingBench(
                inputs: inputs,
                onCraft: onCraft,
                onInputTap: onInputTap,
                recipe: recipeFor(inputs),
              ),
            ),
            Expanded(
              child: InventoryGrid(
                inventory: inventory,
                onTap: onInventoryTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
