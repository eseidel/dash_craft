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
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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

class OutputWell extends StatelessWidget {
  const OutputWell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ItemWell();
  }
}

class CraftingRow extends StatelessWidget {
  const CraftingRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        Expanded(child: ItemWell()),
        Expanded(child: ItemWell()),
        Expanded(child: ItemWell()),
        Spacer(),
        Expanded(child: ItemWell()),
        Spacer(),
        Expanded(child: OutputWell()),
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
    return GridView.builder(
        itemCount: 25,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemBuilder: (BuildContext ctx, index) {
          return ItemWell(stack: inventory.stackAt(index));
        });
  }
}

// class BasicGrid extends StatelessWidget {
//   const BasicGrid({
//     Key? key,
//     required this.columnCount,
//     required this.rowCount,
//     required this.children,
//     this.gap,
//     this.padding,
//     this.margin,
//     this.emptyChild = const SizedBox.shrink(),
//   })  : assert(children.length < columnCount * rowCount,
//             'Cannot layout more children than columnCount * rowCount'),
//         super(key: key);

//   final int columnCount;
//   final int rowCount;
//   final List<Widget> children;
//   final double? gap;
//   final EdgeInsets? padding;
//   final EdgeInsets? margin;
//   final Widget emptyChild;

//   @override
//   Widget build(BuildContext context) {
//     final List<Widget> widgets = [];

//     final childrenLength = children.length;
//     for (int i = 0; i < rowCount; i++) {
//       final List<Widget> row = [];
//       for (int x = 0; x < columnCount; x++) {
//         final index = i * columnCount + x;
//         if (index <= childrenLength - 1) {
//           row.add(SizedBox(child: children[index]));
//         } else {
//           row.add(Expanded(child: emptyChild));
//         }
//         if (x != columnCount - 1) {
//           row.add(SizedBox(width: gap));
//         }
//       }
//       widgets.add(Row(children: row));
//       if (i != rowCount - 1) {
//         widgets.add(SizedBox(height: gap));
//       }
//     }

//     return Container(
//       padding: padding,
//       margin: margin,
//       child: Column(children: widgets),
//     );
//   }
// }

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Inventory inventory = Inventory();

  void _tryCraft() {
    // Check if valid recipe
    // Learn about the recipe requirements if necessary
    // Take items
    // If successful, add results to inventory.
    // Refill slots if needed.

    // What do we do on failure?
    setState(() {
      inventory.tryAdd(ItemStack(type: banana, count: 70));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
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
          const CraftingRow(),
          const Spacer(),
          Expanded(flex: 2, child: InventoryView(inventory: inventory)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tryCraft,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
