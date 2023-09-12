import 'package:flutter/material.dart';

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
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: Colors.deepPurple,
      child: Text(item.toString()),
    );
  }
}

class InventoryGrid extends StatelessWidget {
  const InventoryGrid({
    required this.inventory,
    super.key,
  });

  final List<Item> inventory;

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
          if (index >= inventory.length) {
            return const SizedBox();
          }
          return ItemWidget(item: inventory[index]);
        },
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<Item> inventory = [];

  void gather() {
    setState(() {
      inventory.add(Item.banana);
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
            ElevatedButton(onPressed: gather, child: const Text('Gather')),
            Expanded(child: InventoryGrid(inventory: inventory)),
          ],
        ),
      ),
    );
  }
}
