class Exercise {
  final int? id;
  final String name;
  final String muscleGroup;
  final String? description;
  final String difficulty;

  Exercise({
    this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
    required this.difficulty,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as int?,
    name: json['name'] as String,
    muscleGroup: json['muscleGroup'] as String,
    description: json['description'] as String?,
    difficulty: json['difficulty'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'muscleGroup': muscleGroup,
    'description': description,
    'difficulty': difficulty,
  };
}