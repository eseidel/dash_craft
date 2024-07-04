import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logic/doc.dart';
import 'package:yaml/yaml.dart';

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

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

extension on Item {
  String get assetKey {
    final assetName = name.replaceAll(' ', '');
    return 'assets/doc/${assetName}_Normal.png';
  }
}

extension on MeTool {
  String get assetKey {
    final assetName = name.replaceAll(' ', '');
    return 'assets/doc/${assetName}_Normal.png';
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    required this.item,
    super.key,
    this.width = 100,
    this.height = 100,
  });

  final Item? item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return SizedBox(width: width, height: height);
    }
    return Image.asset(
      item!.assetKey,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.deepPurple,
          child: Text(item.toString()),
        );
      },
    );
  }
}

class ToolWidget extends StatelessWidget {
  const ToolWidget({
    required this.tool,
    super.key,
    this.width = 100,
    this.height = 100,
  });

  final MeTool tool;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      tool.assetKey,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: Text(tool.name),
        );
      },
    );
  }
}

class RecipeWidget extends StatelessWidget {
  const RecipeWidget({
    required this.recipe,
    super.key,
    this.width = 100,
    this.height = 100,
  });

  final Recipe? recipe;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (recipe == null) {
      return SizedBox(width: width, height: width);
    }
    // TODO(eseidel): Support multiple outputs.
    return Image.asset(
      recipe!.outputs.keys.first.assetKey,
      width: width,
      height: width,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: width,
          child: Text(recipe!.name),
        );
      },
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
    return Row(
      children: [
        InputTray(items: inputs, onTap: onInputTap),
        const ToolWidget(tool: MeTool.hand),
        RecipeWidget(recipe: recipe),
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

class GameView extends StatelessWidget {
  const GameView({
    required this.inputs,
    required this.inventory,
    required this.errorMessage,
    required this.onGather,
    required this.onInventoryTap,
    required this.onInputTap,
    required this.onCraft,
    required this.recipe,
    required this.onShowMySkills,
    required this.onShowMinionSkills,
    super.key,
  });

  final List<Item> inputs;
  final List<Item> inventory;
  final String? errorMessage;
  final void Function() onGather;
  final void Function(Item) onInventoryTap;
  final void Function(Item) onInputTap;
  final void Function(List<Item> inputs) onCraft;
  final void Function() onShowMySkills;
  final void Function() onShowMinionSkills;
  final Recipe? recipe;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: onShowMySkills,
                child: const Text('Me'),
              ),
              ElevatedButton(
                onPressed: onShowMinionSkills,
                child: const Text('Minion'),
              ),
            ],
          ),
          ElevatedButton(onPressed: onGather, child: const Text('Gather')),
          ErrorMessage(message: errorMessage),
          Expanded(
            child: CraftingBench(
              inputs: inputs,
              onCraft: onCraft,
              onInputTap: onInputTap,
              recipe: recipe,
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
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final inputs = <Item>[];
  final inventory = <Item>[];
  late final DOC? _rules;
  String? errorMessage;

  bool isLoaded() => _rules != null;
  Rules get rules => _rules!;
  DOC get doc => _rules!;

  @override
  void initState() {
    super.initState();
    loadRules(); // async, not awaited
  }

  Future<void> loadRules() async {
    Future<YamlMap> loadYamlMap(String key) {
      final text = rootBundle.loadString('packages/logic/assets/$key.yaml');
      return text.then((text) => loadYaml(text) as YamlMap);
    }

    final items = ItemSet.fromYaml(await loadYamlMap('items'));
    final recipes = RecipeSet.fromYaml(await loadYamlMap('recipes'), items);
    final tasks = TaskSet.fromYaml(await loadYamlMap('tasks'), items);
    final rules = DOC(items: items, recipes: recipes, tasks: tasks);
    setState(() {
      _rules = rules;
    });
  }

  Recipe? _recipeFor(List<Item> items) {
    if (items.length != 1) {
      return null;
    }
    if (items[0] == doc.banana) {
      return doc.peeledBananaRecipe;
    }
    return null;
  }

  void onGather() {
    setState(() {
      // TODO(eseidel): Gather based on rules + current state.
      inventory.add(doc.banana);
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
    // TODO(eseidel): Craft based on rules + current state.
    final recipe = _recipeFor(inputs);
    if (recipe == null) {
      setState(() {
        errorMessage = 'No recipe found';
      });
      return;
    }
    setState(() {
      inputs.clear();
      for (final entry in recipe.outputs.entries) {
        for (var i = 0; i < entry.value; i++) {
          inventory.add(entry.key);
        }
      }
    });
  }

  void onShowMySkills() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return const SkillSheet(title: 'My Skills');
      },
    );
  }

  void onShowMinionSkills() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return const SkillSheet(title: 'Minion Skills');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameView(
        inputs: inputs,
        inventory: inventory,
        errorMessage: errorMessage,
        onGather: onGather,
        onInventoryTap: onInventoryTap,
        onInputTap: onInputTap,
        onCraft: onCraft,
        recipe: _recipeFor(inputs),
        onShowMySkills: onShowMySkills,
        onShowMinionSkills: onShowMinionSkills,
      ),
    );
  }
}

class SkillSheet extends StatelessWidget {
  const SkillSheet({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.amber,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title),
            ElevatedButton(
              child: const Text('Close BottomSheet'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
