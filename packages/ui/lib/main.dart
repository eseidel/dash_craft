import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logic/game.dart';
import 'package:logic/logic.dart';
import 'package:logic/rules.dart';
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
  });

  final ItemStack? stack;
  final void Function(ItemStack) onTap;

  @override
  Widget build(BuildContext context) {
    if (stack == null) {
      return ItemStackWidget(stack: stack);
    }
    return GestureDetector(
      child: ItemStackWidget(stack: stack),
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

extension on MeTool {
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
  const InputTray({required this.inputs, required this.onTap, super.key});

  final CraftingInputs inputs;
  final void Function(ItemStack) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.deepPurple,
      child: Row(
        children: [0, 1, 2].map((index) {
          return TappableItemStack(stack: inputs[index], onTap: onTap);
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

  final CraftingInputs inputs;
  final Recipe? recipe;
  final void Function(ItemStack) onInputTap;
  final void Function(CraftingInputs inputs) onCraft;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InputTray(inputs: inputs, onTap: onInputTap),
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

  final Inventory inventory;
  final void Function(ItemStack) onTap;

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
          return TappableItemStack(stack: inventory[index], onTap: onTap);
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
    required this.meEnergy,
    required this.minionEnergy,
    super.key,
  });

  final CraftingInputs inputs;
  final Inventory inventory;
  final String? errorMessage;
  final void Function() onGather;
  final void Function(ItemStack) onInventoryTap;
  final void Function(ItemStack) onInputTap;
  final void Function(CraftingInputs inputs) onCraft;
  final void Function() onShowMySkills;
  final void Function() onShowMinionSkills;
  final Recipe? recipe;
  final int meEnergy;
  final int minionEnergy;

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
              Text(meEnergy.toString()),
              const SizedBox(width: 20),
              Text(minionEnergy.toString()),
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
  late final DOC? _rules;
  String? errorMessage;
  Game game = Game();

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

  Recipe? _recipeFor(CraftingInputs inputs) {
    final result = doc.cookbook.findRecipe(inputs);
    if (result == null) {
      return null;
    }
    // We don't yet support multiples.
    if (result.count > 1) {
      return null;
    }
    return result.recipe;
  }

  void onGather() {
    final action = SendMinion(doc: doc);
    setState(() {
      game.apply(action);
    });
  }

  void onInventoryTap(ItemStack stack) {
    if (game.state.craftingInputs.hasRoomFor(stack)) {
      setState(() {
        errorMessage = 'Input tray is full';
      });
      return;
    }
    setState(() {
      // We don't have a Transfer action yet, so implement it ourselves.
      game.state = game.state.copyWith(
        craftingInputs:
            game.state.craftingInputs.copyWith(added: stack.toList()),
        inventory: game.state.inventory.copyWith(removed: stack.toList()),
      );
    });
  }

  void onInputTap(ItemStack stack) {
    if (!game.state.inventory.hasRoomFor(stack)) {
      setState(() {
        errorMessage = 'Inventory full';
      });
      return;
    }
    setState(() {
      // We don't have a Transfer action yet, so implement it ourselves.
      game.state = game.state.copyWith(
        craftingInputs:
            game.state.craftingInputs.copyWith(removed: stack.toList()),
        inventory: game.state.inventory.copyWith(added: stack.toList()),
      );
    });
  }

  void onCraft(CraftingInputs inputs) {
    // TODO(eseidel): Craft based on rules + current state.
    // Should use Game.apply.
    final recipe = _recipeFor(inputs);
    if (recipe == null) {
      setState(() {
        errorMessage = 'No recipe found';
      });
      return;
    }
    final toAdd = <Item>[];
    for (final entry in recipe.outputs.entries) {
      for (var i = 0; i < entry.value; i++) {
        toAdd.add(entry.key);
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

    setState(() {
      game.state = game.state.copyWith(
        craftingInputs: const CraftingInputs.empty(),
        inventory: game.state.inventory.copyWith(added: toAdd),
      );
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

  @override
  Widget build(BuildContext context) {
    final inputs = game.state.craftingInputs;
    return Scaffold(
      body: GameView(
        inputs: game.state.craftingInputs,
        inventory: game.state.inventory,
        errorMessage: errorMessage,
        onGather: onGather,
        onInventoryTap: onInventoryTap,
        onInputTap: onInputTap,
        onCraft: onCraft,
        recipe: _recipeFor(inputs),
        onShowMySkills: onShowMySkills,
        onShowMinionSkills: onShowMinionSkills,
        meEnergy: game.state.meEnergy,
        minionEnergy: game.state.minionEnergy,
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
            return Text('${skill.displayName}: ${skills[skill]}');
          }),
        ],
      ),
    );
  }
}
