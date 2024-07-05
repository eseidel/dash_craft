import 'package:collection/collection.dart';
import 'package:logic/src/items.dart';
import 'package:yaml/yaml.dart';

enum TaskType {
  gather,
  lumberjack,
  hunt,
  fish,
  treasureHunt;

  static TaskType fromString(String name) {
    final type = TaskType.values
        .firstWhereOrNull((e) => e.toString() == 'TaskType.$name');
    if (type == null) {
      throw ArgumentError('Unknown task type: $name');
    }
    return type;
  }
}

class MinionTask {
  const MinionTask({
    required this.item,
    required this.type,
    required this.energy,
    required this.minSkill,
  });

  factory MinionTask.fromYaml(YamlMap yaml, TaskType type, ItemSet items) {
    final item = items[yaml['item'] as String];
    return MinionTask(
      type: type,
      item: item,
      energy: yaml['energy'] as int?,
      minSkill: yaml['minSkill'] as int? ?? 0,
    );
  }

  final TaskType type;
  final Item item;
  final int? energy;
  final int minSkill;
}

class TaskSet {
  TaskSet._(this.all);

  factory TaskSet.fromYaml(YamlMap yaml, ItemSet items) {
    final tasks = <MinionTask>[];
    final tasksMap = yaml['tasks'] as YamlMap;
    for (final taskTypeString in tasksMap.keys) {
      final taskType = TaskType.fromString(taskTypeString as String);
      for (final taskYaml in tasksMap[taskTypeString] as YamlList) {
        final taskMap = taskYaml as YamlMap;
        final task = MinionTask.fromYaml(taskMap, taskType, items);
        tasks.add(task);
      }
    }
    return TaskSet._(tasks);
  }

  Iterable<MinionTask> withType(TaskType type) {
    return all.where((t) => t.type == type);
  }

  final List<MinionTask> all;
}
