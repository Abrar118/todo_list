class Subtask {
  final String id;
  final String title;
  final bool isCompleted;
  final int sortIndex;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.sortIndex,
    required this.createdAt,
    this.completedAt,
  });

  Subtask copyWith({
    String? title,
    bool? isCompleted,
    int? sortIndex,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) => Subtask(
    id: id,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
    sortIndex: sortIndex ?? this.sortIndex,
    createdAt: createdAt,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
  );

  /// A fresh incomplete copy used when materializing the next recurring
  /// occurrence.
  Subtask resetForNewOccurrence(String newId, DateTime now) => Subtask(
    id: newId,
    title: title,
    isCompleted: false,
    sortIndex: sortIndex,
    createdAt: now,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': isCompleted,
    'sortIndex': sortIndex,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (completedAt != null)
      'completedAt': completedAt!.toUtc().toIso8601String(),
  };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    isCompleted: json['completed'] as bool? ?? false,
    sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    completedAt: DateTime.tryParse(
      json['completedAt'] as String? ?? '',
    )?.toLocal(),
  );
}
