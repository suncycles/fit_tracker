class WorkoutSet {
  final int? id;
  final int workoutId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double weight;
  final String? notes;

  WorkoutSet({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.notes,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    id: json['id'] as int?,
    workoutId: json['workoutId'] as int,
    exerciseId: json['exerciseId'] as int,
    setNumber: json['setNumber'] as int,
    reps: json['reps'] as int,
    weight: (json['weight'] as num).toDouble(),
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'workoutId': workoutId,
    'exerciseId': exerciseId,
    'setNumber': setNumber,
    'reps': reps,
    'weight': weight,
    'notes': notes,
  };
}