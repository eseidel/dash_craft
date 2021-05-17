import 'dart:math';

import 'inventory.dart';

class Fetcher {
  final Random _random = Random();

  ItemStack gather() {
    var gatherTypes = [
      banana,
      stone,
    ];
    var randomType = gatherTypes[_random.nextInt(gatherTypes.length)];
    return ItemStack(type: randomType, count: 2);
  }
}

var fetcher = Fetcher();
