import 'date_only.dart';

enum GoalColor { lime, cyan, amber, coral, violet }

class GoalCheckpoint {
  final String id;
  final String title;
  final bool isCompleted;

  const GoalCheckpoint({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  GoalCheckpoint copyWith({String? title, bool? isCompleted}) => GoalCheckpoint(
    id: id,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory GoalCheckpoint.fromJson(Map<String, dynamic> json) => GoalCheckpoint(
    id: json['id'] as String,
    title: json['title'] as String,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is GoalCheckpoint &&
      other.id == id &&
      other.title == title &&
      other.isCompleted == isCompleted;

  @override
  int get hashCode => Object.hash(id, title, isCompleted);
}

class Goal {
  final String id;
  final String title;
  final String description;
  final DateOnly targetDate;
  final DateOnly createdOn;
  final GoalColor color;
  final int manualProgress;
  final List<GoalCheckpoint> checkpoints;

  const Goal({
    required this.id,
    required this.title,
    this.description = '',
    required this.targetDate,
    required this.createdOn,
    required this.color,
    this.manualProgress = 0,
    this.checkpoints = const [],
  });

  int get completedCheckpointCount =>
      checkpoints.where((checkpoint) => checkpoint.isCompleted).length;

  double get progress => checkpoints.isNotEmpty
      ? completedCheckpointCount / checkpoints.length
      : manualProgress.clamp(0, 100) / 100;

  bool get isCompleted => progress >= 1;

  Goal copyWith({
    String? title,
    String? description,
    DateOnly? targetDate,
    GoalColor? color,
    int? manualProgress,
    List<GoalCheckpoint>? checkpoints,
  }) => Goal(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    targetDate: targetDate ?? this.targetDate,
    createdOn: createdOn,
    color: color ?? this.color,
    manualProgress: (manualProgress ?? this.manualProgress).clamp(0, 100),
    checkpoints: List.unmodifiable(checkpoints ?? this.checkpoints),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'targetDate': targetDate.toString(),
    'createdOn': createdOn.toString(),
    'color': color.name,
    'manualProgress': manualProgress,
    'checkpoints': checkpoints
        .map((checkpoint) => checkpoint.toJson())
        .toList(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    targetDate: DateOnly.parse(json['targetDate'] as String),
    createdOn: DateOnly.parse(json['createdOn'] as String),
    color: GoalColor.values.firstWhere(
      (color) => color.name == json['color'],
      orElse: () => GoalColor.lime,
    ),
    manualProgress: (json['manualProgress'] as num?)?.toInt() ?? 0,
    checkpoints: List.unmodifiable(
      (json['checkpoints'] as List<dynamic>? ?? const []).whereType<Map>().map(
        (value) => GoalCheckpoint.fromJson(Map<String, dynamic>.from(value)),
      ),
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is Goal &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.targetDate == targetDate &&
      other.createdOn == createdOn &&
      other.color == color &&
      other.manualProgress == manualProgress &&
      _listEquals(other.checkpoints, checkpoints);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    targetDate,
    createdOn,
    color,
    manualProgress,
    Object.hashAll(checkpoints),
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
