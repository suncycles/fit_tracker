class Workout {
  final int? id;
  final String date;
  final String name;
  final String? notes;

  Workout({
    this.id,
    required this.date,
    required this.name,
    this.notes,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'] as int?,
    date: json['date'] as String,
    name: json['name'] as String,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'name': name,
    'notes': notes,
  };
}