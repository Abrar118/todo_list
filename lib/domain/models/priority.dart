enum TaskPriority {
  none,
  low,
  medium,
  high;

  String get label => switch (this) {
    TaskPriority.none => 'None',
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };

  static TaskPriority fromName(String? name) => TaskPriority.values.firstWhere(
    (p) => p.name == name,
    orElse: () => TaskPriority.none,
  );
}
