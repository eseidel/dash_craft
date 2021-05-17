import 'package:dash_craft/activity.dart';
import 'package:dash_craft/inventory.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dash Craft',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DashCraft(),
    );
  }
}

@immutable
class ItemWell extends StatelessWidget {
  final ItemStack? stack;

  const ItemWell({Key? key, this.stack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 2)),
        child: Text("${stack?.count} ${stack?.type.name}"),
      ),
    );
  }
}

class ToolWell extends StatelessWidget {
  final ItemStack? tool;
  const ToolWell({Key? key, this.tool}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ItemWell(stack: tool);
  }
}

class OutputWell extends StatelessWidget {
  const OutputWell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ItemWell();
  }
}

class CraftingRow extends StatelessWidget {
  final CraftingInputs craftingInputs;
  final ItemStack? tool = null;
  final VoidCallback tryCraft;
  const CraftingRow({
    Key? key,
    required this.craftingInputs,
    required this.tryCraft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: ItemWell(stack: craftingInputs.first)),
        Expanded(child: ItemWell(stack: craftingInputs.second)),
        Expanded(child: ItemWell(stack: craftingInputs.third)),
        const Spacer(),
        Expanded(child: ToolWell(tool: tool)),
        const Spacer(),
        const Expanded(child: OutputWell()),
        ElevatedButton.icon(
          onPressed: tryCraft,
          icon: const Icon(Icons.handyman),
          label: const Text('Craft'),
        ),
      ],
    );
  }
}

class InventoryView extends StatelessWidget {
  final Inventory inventory;
  const InventoryView({
    Key? key,
    required this.inventory,
  }) : super(key: key);

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
            return ItemWell(stack: inventory.stackAt(index));
          }),
    );
  }
}

class DashCraft extends StatefulWidget {
  const DashCraft({Key? key}) : super(key: key);

  @override
  State<DashCraft> createState() => _DashCraftState();
}

class CraftingInputs {
  late List<ItemStack> _stacks;

  CraftingInputs({List<ItemStack>? stacks})
      : assert(stacks == null || stacks.length <= 3) {
    _stacks = stacks ?? [];
  }
  ItemStack? get first => _stacks.isNotEmpty ? _stacks.first : null;
  ItemStack? get second => _stacks.length > 1 ? _stacks[1] : null;
  ItemStack? get third => _stacks.length > 2 ? _stacks[2] : null;
}

class _DashCraftState extends State<DashCraft> {
  CraftingInputs craftingInputs = CraftingInputs();
  Inventory inventory = Inventory();

  void _tryCraft() {
    // Check if valid recipe
    // Learn about the recipe requirements if necessary
    // Take items
    // If successful, add results to inventory.
    // Refill slots if needed.

    // What do we do on failure?
    setState(() {
      inventory.tryAdd(fetcher.gather());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GameArea(
            craftingInputs: craftingInputs,
            inventory: inventory,
            tryCraft: _tryCraft),
      ),
    );
  }
}

class GameArea extends StatelessWidget {
  const GameArea({
    Key? key,
    required this.craftingInputs,
    required this.inventory,
    required this.tryCraft,
  }) : super(key: key);

  final CraftingInputs craftingInputs;
  final Inventory inventory;
  final VoidCallback tryCraft;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Top(
              craftingInputs: craftingInputs,
              tryCraft: tryCraft,
            ),
          ),
          Expanded(flex: 2, child: InventoryView(inventory: inventory)),
        ],
      ),
    );
  }
}

class Top extends StatelessWidget {
  const Top({Key? key, required this.craftingInputs, required this.tryCraft})
      : super(key: key);

  final CraftingInputs craftingInputs;
  final VoidCallback tryCraft;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const <Widget>[
                Text('Me'),
                Text('Mentor'),
                Text('Fetch'),
              ]),
        ),
        const Spacer(),
        CraftingRow(craftingInputs: craftingInputs, tryCraft: tryCraft),
        const Spacer(),
      ],
    );
  }
}
