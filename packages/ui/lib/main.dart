import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logic/game.dart';
import 'package:logic/logic.dart';
import 'package:logic/rules.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

const inputSize = 3;

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

class TappableItemStack extends StatelessWidget {
  const TappableItemStack({
    required this.stack,
    required this.onTap,
    super.key,
    this.disabled = false,
  });

  final ItemStack? stack;
  final void Function(ItemStack) onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    if (stack == null) {
      return ItemStackWidget(stack: stack);
    }
    if (disabled) {
      return Opacity(opacity: 0.5, child: ItemStackWidget(stack: stack));
    }
    return GestureDetector(
      child: Draggable<ItemStack>(
        feedback: ItemStackWidget(stack: stack),
        child: ItemStackWidget(stack: stack),
      ),
      onTap: () => onTap.call(stack!),
    );
  }
}

String _assetKey(String name) {
  final assetName = name.replaceAll(' ', '');
  return 'assets/doc/${assetName}_Normal.png';
}

extension on Item {
  String get assetKey => _assetKey(name.replaceAll(' ', ''));
}

extension on ToolType {
  String get assetKey => _assetKey(name.replaceAll(' ', ''));
}

class ItemStackWidget extends StatelessWidget {
  const ItemStackWidget({
    required this.stack,
    super.key,
    this.width = 100,
    this.height = 100,
  });

  final ItemStack? stack;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (stack == null) {
      return SizedBox(width: width, height: height);
    }
    final item = stack!.item;
    final backgroundKey = _assetKey('ItemBoxEmpty');
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Image.asset(
            backgroundKey,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: Colors.grey,
              );
            },
          ),
          Image.asset(
            item.assetKey,
            errorBuilder: (context, error, stackTrace) {
              return Text(item.toString());
            },
          ),
          if (stack!.count > 1)
            Positioned(
              right: 5,
              top: 2,
              child: Text(
                textAlign: TextAlign.right,
                stack!.count.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
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

  final ToolContainer tool;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final toolType = tool.toolType;
    return Image.asset(
      toolType.assetKey,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: Text(toolType.name),
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
  const InputTray({
    required this.inputs,
    required this.onTap,
    super.key,
    this.disabled = false,
  });

  final InputsContainer inputs;
  final void Function(ItemStack) onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.deepPurple,
      child: Row(
        children: [0, 1, 2].map((index) {
          return TappableItemStack(
            stack: inputs[index],
            onTap: onTap,
            disabled: disabled,
          );
        }).toList(),
      ),
    );
  }
}

class CraftingBenchWidget extends StatelessWidget {
  const CraftingBenchWidget({
    required this.bench,
    required this.onCraft,
    required this.onInputTap,
    required this.onToolTap,
    this.recipe,
    this.disabled = false,
    super.key,
  });

  final CraftingBench bench;
  final Recipe? recipe;
  final void Function(ItemStack) onInputTap;
  final void Function(CraftingBench bench) onCraft;
  final void Function(ToolContainer) onToolTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InputTray(inputs: bench.inputs, onTap: onInputTap),
        GestureDetector(
          onTap: () => onToolTap(bench.tool),
          child: ToolWidget(tool: bench.tool),
        ),
        RecipeWidget(recipe: recipe),
        ElevatedButton(
          onPressed: disabled ? null : () => onCraft(bench),
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
    this.filter,
    super.key,
  });

  final Inventory inventory;
  final void Function(ItemStack) onTap;
  final bool Function(ItemStack?)? filter;

  @override
  Widget build(BuildContext context) {
    final filter = this.filter;
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        itemCount: 25,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemBuilder: (BuildContext ctx, index) {
          final stack = inventory[index];
          return TappableItemStack(
            stack: stack,
            onTap: onTap,
            disabled: filter != null && !filter(stack),
          );
        },
      ),
    );
  }
}

class StatusMessage extends StatelessWidget {
  const StatusMessage({required this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return const SizedBox();
    }
    return Text(message!);
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
    return Text(message!, style: const TextStyle(color: Colors.red));
  }
}

class FeedTarget extends StatelessWidget {
  const FeedTarget({required this.name, required this.energy, super.key});

  final String name;
  final int energy;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItemStack>(
      builder: (
        BuildContext context,
        List<ItemStack?> candidateData,
        List<dynamic> rejectedData,
      ) {
        final highlighted = candidateData.isNotEmpty;
        return Container(
          width: 100,
          height: 100,
          color: highlighted ? Colors.green : Colors.blue,
          child: Column(
            children: [
              Text(name),
              Text('Energy: $energy'),
            ],
          ),
        );
      },
    );
  }
}

class GameView extends StatelessWidget {
  const GameView({
    required this.bench,
    required this.inventory,
    required this.onGather,
    required this.onInventoryTap,
    required this.onInputTap,
    required this.onCraft,
    required this.onShowMySkills,
    required this.onShowMinionSkills,
    required this.meEnergy,
    required this.minionEnergy,
    required this.onToolTap,
    this.recipe,
    this.errorMessage,
    this.statusMessage,
    this.selectingTool = false,
    super.key,
  });

  final CraftingBench bench;
  final Inventory inventory;
  final String? errorMessage;
  final String? statusMessage;
  final void Function() onGather;
  final void Function(ItemStack) onInventoryTap;
  final void Function(ItemStack) onInputTap;
  final void Function(ToolContainer) onToolTap;
  final void Function(CraftingBench bench) onCraft;
  final void Function() onShowMySkills;
  final void Function() onShowMinionSkills;
  final Recipe? recipe;
  final int meEnergy;
  final int minionEnergy;
  final bool selectingTool;

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
          Row(
            children: [
              FeedTarget(name: 'Me', energy: meEnergy),
              const SizedBox(width: 20),
              FeedTarget(name: 'Minion', energy: minionEnergy),
            ],
          ),
          ElevatedButton(onPressed: onGather, child: const Text('Gather')),
          StatusMessage(message: statusMessage),
          ErrorMessage(message: errorMessage),
          Expanded(
            child: CraftingBenchWidget(
              bench: bench,
              onCraft: onCraft,
              onInputTap: onInputTap,
              recipe: recipe,
              disabled: selectingTool,
              onToolTap: onToolTap,
            ),
          ),
          Expanded(
            child: InventoryGrid(
              inventory: inventory,
              onTap: onInventoryTap,
              filter:
                  selectingTool ? (stack) => stack?.item.tool != null : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  DOC? _rules;
  String? errorMessage;
  String? statusMessage;
  Game? _game;
  late String savePath;

  bool isLoaded() => _rules != null && _game != null;
  Rules get rules => _rules!;
  DOC get doc => _rules!;
  Game get game => _game!;

  // Does this need to be a state machine (enum)?
  bool selectingTool = false;

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
    _rules = rules;
    final game = await loadGame(rules);
    setState(() {
      _game = game;
    });
  }

  Future<String> getSavePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'game.json');
  }

  Future<Game> loadGame(Rules rules) async {
    savePath = await getSavePath();
    final file = File(savePath);
    if (!file.existsSync()) {
      print('No save file found at $savePath, starting new game.');
      return Game();
    }
    final text = await file.readAsString();
    final json = jsonDecode(text);
    return Game.fromJson(json as Map<String, dynamic>, rules.items);
  }

  void onGather() {
    final action = SendMinion(doc: doc);
    setState(() {
      game.apply(action);
    });
  }

  void onInventoryTap(ItemStack stack) {
    if (selectingTool) {
      // If tool, transfer to the tool slot rather than bench.
      if (stack.item.tool != null) {
        assert(game.state.bench.tool.isEmpty, 'Tool slot should be empty');
        setState(() {
          game.state = game.state.copyWith(
            bench: game.state.bench.copyWith(
              tool: ToolContainer(tool: ItemStack(type: stack.item)),
            ),
            inventory: game.state.inventory.copyWith(removed: [stack.item]),
          );
        });
        toggleToolSelection();
        return;
      }
      // Otherwise toggle off tool selection.

      toggleToolSelection();
      return;
    }

    if (!game.state.bench.inputs.hasRoomFor(stack)) {
      setState(() {
        errorMessage = 'Input tray is full';
      });
      return;
    }
    setState(() {
      // We don't have a Transfer action yet, so implement it ourselves.
      final state = game.state;
      final bench = state.bench;
      game.state = state.copyWith(
        bench: bench.copyWith(
          inputs: bench.inputs.copyWith(added: [stack.item]),
        ),
        inventory: state.inventory.copyWith(removed: [stack.item]),
      );
    });
  }

  void onInputTap(ItemStack stack) {
    if (selectingTool) {
      // Always cancel tool selection when tapping an input slot.
      toggleToolSelection();
      return;
    }

    if (!game.state.inventory.hasRoomFor(stack)) {
      setState(() {
        errorMessage = 'Inventory full';
      });
      return;
    }
    setState(() {
      // We don't have a Transfer action yet, so implement it ourselves.
      final state = game.state;
      final bench = state.bench;
      game.state = state.copyWith(
        bench: bench.copyWith(
          inputs: bench.inputs.copyWith(removed: [stack.item]),
        ),
        inventory: state.inventory.copyWith(added: [stack.item]),
      );
    });
  }

  void onCraft(CraftingBench bench) {
    // TODO(eseidel): Use Craft action + validate?

    final result = doc.cookbook.findRecipe(bench);
    if (result == null) {
      setState(() {
        errorMessage = 'No recipe found';
      });
      return;
    }
    // TODO(eseidel): Use stacks instead of items?
    // This does not respect percentage based outputs.
    final toAdd = <Item>[];
    for (var count = 0; count < result.count; count++) {
      for (final entry in result.recipe.outputs.entries) {
        for (var i = 0; i < entry.value; i++) {
          toAdd.add(entry.key);
        }
      }
    }
    // This should only fail if the 100% chance outputs don't fit.
    // Sometimes outputs will just be discarded if they don't fit.
    // if (!game.state.inventory.hasRoomFor(toAdd)) {
    //   setState(() {
    //     errorMessage = 'Inventory full';
    //   });
    //   return;
    // }

    // Should use Game.apply.
    setState(() {
      game.state = game.state.copyWith(
        bench: const CraftingBench.empty(),
        inventory: game.state.inventory.copyWith(added: toAdd),
      );
    });
  }

  void onToolTap(ToolContainer tool) {
    final stack = tool.stack;
    // If already have a tool, transfer the tool back to the inventory.
    if (stack != null) {
      // If can't transfer tool to inventory, show error message.
      if (!game.state.inventory.hasRoomFor(stack)) {
        setState(() {
          errorMessage = 'Inventory full';
        });
        return;
      }

      setState(() {
        // We don't have a Transfer action yet, so implement it ourselves.
        final state = game.state;
        final bench = state.bench;
        game.state = state.copyWith(
          bench: bench.copyWith(tool: const ToolContainer.empty()),
          inventory: state.inventory.copyWith(added: [stack.item]),
        );
      });
      return;
    }

    toggleToolSelection();
  }

  void toggleToolSelection() {
    // If we already have a tool selected, transfer it to inventory if possible.

    setState(() {
      if (selectingTool) {
        statusMessage = null;
      } else {
        statusMessage = 'Select a tool';
      }
      selectingTool = !selectingTool;
    });
  }

  void onShowMySkills() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SkillSheet(
          title: 'My Skills',
          skillList: Skill.mySkills,
          skills: game.state.skills,
        );
      },
    );
  }

  void onShowMinionSkills() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SkillSheet(
          title: 'Minion Skills',
          skillList: Skill.minionSkills,
          skills: game.state.skills,
        );
      },
    );
  }

  Recipe? knownRecipeFor(CraftingBench bench) {
    // TODO(eseidel): respect if we've learned recipes or not.
    return doc.cookbook.findRecipe(bench)?.recipe;
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded()) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final bench = game.state.bench;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dash Craft'),
      ),
      drawer: DebugDrawer(game: game, savePath: savePath),
      body: GameView(
        bench: bench,
        inventory: game.state.inventory,
        errorMessage: errorMessage,
        statusMessage: statusMessage,
        onGather: onGather,
        onInventoryTap: onInventoryTap,
        onInputTap: onInputTap,
        onCraft: onCraft,
        recipe: knownRecipeFor(bench),
        onShowMySkills: onShowMySkills,
        onShowMinionSkills: onShowMinionSkills,
        onToolTap: onToolTap,
        meEnergy: game.state.meEnergy,
        minionEnergy: game.state.minionEnergy,
        selectingTool: selectingTool,
      ),
    );
  }
}

class DebugDrawer extends StatelessWidget {
  const DebugDrawer({required this.game, required this.savePath, super.key});

  final Game game;
  final String savePath;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            title: const Text('Save'),
            onTap: () async {
              final json = game.toJson();
              final text = jsonEncode(json);
              final file = File(savePath);
              await file.writeAsString(text);
            },
          ),
        ],
      ),
    );
  }
}

class SkillSheet extends StatelessWidget {
  const SkillSheet({
    required this.title,
    required this.skills,
    required this.skillList,
    super.key,
  });

  final String title;
  final Skills skills;
  final List<Skill> skillList;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: [
              Text(title),
              ElevatedButton(
                child: const Text('X'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          ...skillList.map((skill) {
            return Text(
              '${skill.displayName}: ${skills[skill].toStringAsFixed(1)}',
            );
          }),
        ],
      ),
    );
  }
}
