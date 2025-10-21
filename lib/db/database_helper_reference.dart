import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = path_helper.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE exercises (
  id $idType,
  name $textType,
  muscleGroup $textType,
  description TEXT,
  difficulty $textType
)
''');

    await db.execute('''
CREATE TABLE workouts (
  id $idType,
  date $textType,
  name $textType,
  notes TEXT
)
''');

    await db.execute('''
CREATE TABLE workout_sets (
  id $idType,
  workoutId $intType,
  exerciseId $intType,
  setNumber $intType,
  reps $intType,
  weight $realType,
  notes TEXT,
  FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
  FOREIGN KEY (exerciseId) REFERENCES exercises (id)
)
''');

    // Insert sample exercises
    await _insertSampleExercises(db);
  }

  Future<void> _insertSampleExercises(Database db) async {
    final exercises = [
      {'name': 'Bench Press', 'muscleGroup': 'Chest', 'description': 'Lie on bench, press bar up', 'difficulty': 'Intermediate'},
      {'name': 'Push-ups', 'muscleGroup': 'Chest', 'description': 'Classic bodyweight chest exercise', 'difficulty': 'Beginner'},
      {'name': 'Squats', 'muscleGroup': 'Legs', 'description': 'Lower body compound exercise', 'difficulty': 'Intermediate'},
      {'name': 'Deadlift', 'muscleGroup': 'Back', 'description': 'Pull weight from ground', 'difficulty': 'Advanced'},
      {'name': 'Barbell Row', 'muscleGroup': 'Back', 'description': 'Bend over and pull bar to chest', 'difficulty': 'Intermediate'},
      {'name': 'Pull-ups', 'muscleGroup': 'Back', 'description': 'Hang from bar and pull up', 'difficulty': 'Intermediate'},
      {'name': 'Overhead Press', 'muscleGroup': 'Shoulders', 'description': 'Press weight overhead', 'difficulty': 'Intermediate'},
      {'name': 'Lateral Raises', 'muscleGroup': 'Shoulders', 'description': 'Raise dumbbells to sides', 'difficulty': 'Beginner'},
      {'name': 'Bicep Curls', 'muscleGroup': 'Arms', 'description': 'Curl weight up to shoulders', 'difficulty': 'Beginner'},
      {'name': 'Tricep Dips', 'muscleGroup': 'Arms', 'description': 'Lower and raise body on parallel bars', 'difficulty': 'Intermediate'},
      {'name': 'Leg Press', 'muscleGroup': 'Legs', 'description': 'Push platform away with legs', 'difficulty': 'Beginner'},
      {'name': 'Lunges', 'muscleGroup': 'Legs', 'description': 'Step forward and lower body', 'difficulty': 'Beginner'},
      {'name': 'Plank', 'muscleGroup': 'Core', 'description': 'Hold body in straight line', 'difficulty': 'Beginner'},
      {'name': 'Crunches', 'muscleGroup': 'Core', 'description': 'Lift shoulders off ground', 'difficulty': 'Beginner'},
    ];

    for (var exercise in exercises) {
      await db.insert('exercises', exercise);
    }
  }

  Future<List<Exercise>> getExercises({String? muscleGroup, String? search}) async {
    final db = await instance.database;
    
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (muscleGroup != null && muscleGroup.isNotEmpty) {
      where = 'muscleGroup = ?';
      whereArgs.add(muscleGroup);
    }
    
    if (search != null && search.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'name LIKE ?';
      whereArgs.add('%$search%');
    }
    
    final result = await db.query(
      'exercises',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name',
    );
    
    return result.map((json) => Exercise.fromJson(json)).toList();
  }

  Future<List<String>> getMuscleGroups() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT DISTINCT muscleGroup FROM exercises ORDER BY muscleGroup');
    return result.map((row) => row['muscleGroup'] as String).toList();
  }

  Future<int> createWorkout(Workout workout) async {
    final db = await instance.database;
    return await db.insert('workouts', workout.toJson());
  }

  Future<List<Workout>> getWorkouts() async {
    final db = await instance.database;
    final result = await db.query('workouts', orderBy: 'date DESC');
    return result.map((json) => Workout.fromJson(json)).toList();
  }

  Future<Workout?> getWorkout(int id) async {
    final db = await instance.database;
    final result = await db.query('workouts', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Workout.fromJson(result.first);
  }

  Future<int> updateWorkout(Workout workout) async {
    final db = await instance.database;
    return await db.update('workouts', workout.toJson(), where: 'id = ?', whereArgs: [workout.id]);
  }

  Future<int> deleteWorkout(int id) async {
    final db = await instance.database;
    return await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> createWorkoutSet(WorkoutSet set) async {
    final db = await instance.database;
    return await db.insert('workout_sets', set.toJson());
  }

  Future<List<WorkoutSet>> getWorkoutSets(int workoutId) async {
    final db = await instance.database;
    final result = await db.query(
      'workout_sets',
      where: 'workoutId = ?',
      whereArgs: [workoutId],
      orderBy: 'setNumber',
    );
    return result.map((json) => WorkoutSet.fromJson(json)).toList();
  }

  Future<int> updateWorkoutSet(WorkoutSet set) async {
    final db = await instance.database;
    return await db.update('workout_sets', set.toJson(), where: 'id = ?', whereArgs: [set.id]);
  }

  Future<int> deleteWorkoutSet(int id) async {
    final db = await instance.database;
    return await db.delete('workout_sets', where: 'id = ?', whereArgs: [id]);
  }

  Future<Exercise?> getExercise(int id) async {
    final db = await instance.database;
    final result = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Exercise.fromJson(result.first);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}