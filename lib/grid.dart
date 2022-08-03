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
