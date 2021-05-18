import 'package:dash_craft/activity.dart';
import 'package:dash_craft/inventory.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import 'dart:math';

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
  final DragLocation location;

  const ItemWell({
    Key? key,
    this.stack,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 2)),
        child: stack != null
            ? DraggableItem(location: location, stack: stack!)
            : null,
      ),
    );
  }
}

class DraggableItem extends StatelessWidget {
  const DraggableItem({
    Key? key,
    required this.location,
    required this.stack,
  }) : super(key: key);

  final DragLocation location;
  final ItemStack stack;

  @override
  Widget build(BuildContext context) {
    var text = Text("${stack.count} ${stack.type.name}");
    return Draggable<DragInfo>(
      maxSimultaneousDrags: 1,
      data: DragInfo(from: location, stack: stack),
      child: text,
      feedback: text,
    );
  }
}

class ToolWell extends StatelessWidget {
  final ItemStack? tool;
  const ToolWell({Key? key, this.tool}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ItemWell(
      stack: tool,
      location: DragLocation.toolWell,
    );
  }
}

class OutputWell extends StatelessWidget {
  const OutputWell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ItemFrame or similar?
    return Container();
  }
}

class CraftingRow extends StatelessWidget {
  const CraftingRow({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<Game>(
      builder: (context, game, child) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
              child: ItemWell(
                  stack: game.craftingInputs.first,
                  location: DragLocation.craftingTable)),
          Expanded(
              child: ItemWell(
                  stack: game.craftingInputs.second,
                  location: DragLocation.craftingTable)),
          Expanded(
              child: ItemWell(
                  stack: game.craftingInputs.third,
                  location: DragLocation.craftingTable)),
          const Spacer(),
          const Expanded(child: ToolWell(tool: null)),
          const Spacer(),
          const Expanded(child: OutputWell()),
          ElevatedButton.icon(
            onPressed: game.craftPressed,
            icon: const Icon(Icons.handyman),
            label: const Text('Craft'),
          ),
        ],
      ),
    );
  }
}

class InventoryView extends StatelessWidget {
  const InventoryView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Consumer<Game>(
        builder: (context, game, child) => GridView.builder(
            itemCount: 25,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
            ),
            itemBuilder: (BuildContext ctx, index) {
              return ItemWell(
                stack: game.inventory.stackAt(index),
                location: DragLocation.inventory,
              );
            }),
      ),
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

class Game with ChangeNotifier {
  CraftingInputs craftingInputs = CraftingInputs();
  Inventory inventory = Inventory();
  Human me = Human();
  Human minion = Human();

  void eatFood({required ItemStack from, required Human to}) {
    // Reject non-food items?
    if (from.energy == 0) {
      print('no energy!');
      return;
    }
    assert(from.energy > 0); // Eventually not required.
    int missing = to.missingEnergy;
    int canTake = missing ~/ from.type.energy;
    if (canTake == 0) {
      print('can take 0!');
      return;
    }
    int willTake = min(canTake, from.count);
    from.count -= willTake;
    to.energy += willTake * from.type.energy;
    notifyListeners();
  }

  // Drag types
  // Inventory -> Human (destroy stack, change to energy)
  // Crafting Table -> Inventory (move stack, add in position)
  // Inventory -> Slot -> (move to slot)
  // Inventory -> Container -> Add to list
  // Inventory -> Fire -> (destroy stack, change to fuel)
  // Inventory -> Quiver/Rod -> (destroy stack, change to fuel)

  void craftPressed() {
    // Check if valid recipe
    // Learn about the recipe requirements if necessary
    // Take items
    // If successful, add results to inventory.
    // Refill slots if needed.

    // What do we do on failure?
    inventory.tryAdd(fetcher.gather());
    notifyListeners();
  }
}

// Dead code.
enum DragLocation {
  inventory,
  craftingTable,
  me,
  toolWell,
}

// Dead code.
class DragInfo {
  DragLocation from;
  late DragLocation to;
  ItemStack stack;

  DragInfo({required this.from, required this.stack});
}

// Interactions
// Drag around inventory
// Drag from Inventory to crafting table
// Drag from Inventory to tool (e.g. fire, rod, etc)
// Drag from Inventory to person
// Drag from Crafting Table to person
// Drag from Crafting Table to Inventory
// Gather (adds to inventory)
// Craft (takes from crafting table, adds to inventory, auto-fills from inventory)

class _DashCraftState extends State<DashCraft> {
  Game game = Game();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ChangeNotifierProvider.value(
          value: game,
          child: GameArea(
            game: game,
          ),
        ),
      ),
    );
  }
}

class Human {
  static const int maxEnergy = 100;
  int energy = 7;

  int get missingEnergy => maxEnergy - energy;
  double get energyPercent => energy / maxEnergy;
}

class GameArea extends StatelessWidget {
  const GameArea({
    Key? key,
    required this.game,
  }) : super(key: key);

  final Game game;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Expanded(
            flex: 1,
            child: Top(),
          ),
          Expanded(flex: 2, child: InventoryView()),
        ],
      ),
    );
  }
}

class Top extends StatelessWidget {
  const Top({
    Key? key,
  }) : super(key: key);

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
                Expanded(child: Me()),
                Expanded(child: Text('Mentor')),
                Expanded(child: Text('Fetch')),
              ]),
        ),
        const Spacer(),
        const CraftingRow(),
        const Spacer(),
      ],
    );
  }
}

typedef CompleteDrag = Function(DragInfo info);

class Me extends StatelessWidget {
  const Me({
    Key? key,
  }) : super(key: key);

  Color _energyColor(double energyPercent) {
    if (energyPercent < .20) return Colors.red;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    // Should reject food if full!
    return DragTarget<DragInfo>(
      builder: (BuildContext context, List<DragInfo?> candidateData,
              List rejectedData) =>
          Consumer<Game>(
        builder: (context, game, child) => Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: candidateData.isNotEmpty ? Colors.blue : Colors.black),
          ),
          child: Column(
            children: [
              LinearPercentIndicator(
                animation: true,
                animationDuration: 100,
                animateFromLastPercent: true,
                lineHeight: 20.0,
                percent: game.me.energyPercent,
                center: Text('${(game.me.energyPercent * 100).toInt()}'),
                progressColor: _energyColor(game.me.energyPercent),
              ),
              const Text('Me'),
            ],
          ),
        ),
      ),
      onWillAccept: (DragInfo? stack) => stack != null,
      onAccept: (DragInfo stack) {
        var game = context.read<Game>();
        game.eatFood(from: stack.stack, to: game.me);
      },
    );
  }
}
