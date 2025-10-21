import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';


class WorkoutDetailScreen extends StatefulWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  Workout? _workout;
  List<WorkoutSet> _sets = [];
  Map<int, Exercise> _exercises = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    setState(() => _isLoading = true);
    final workout = await DatabaseHelper.instance.getWorkout(widget.workoutId);
    final sets = await DatabaseHelper.instance.getWorkoutSets(widget.workoutId);
    
    final Map<int, Exercise> exercises = {};
    for (var set in sets) {
      if (!exercises.containsKey(set.exerciseId)) {
        final exercise = await DatabaseHelper.instance.getExercise(set.exerciseId);
        if (exercise != null) {
          exercises[set.exerciseId] = exercise;
        }
      }
    }

    setState(() {
      _workout = workout;
      _sets = sets;
      _exercises = exercises;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _workout == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final date = DateTime.parse(_workout!.date);
    final groupedSets = <int, List<WorkoutSet>>{};
    for (var set in _sets) {
      groupedSets.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_workout!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editWorkout,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteWorkout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  if (_workout!.notes != null) ...[
                    const SizedBox(height: 8),
                    Text(_workout!.notes!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            ...groupedSets.entries.map((entry) {
              final exerciseId = entry.key;
              final sets = entry.value;
              final exercise = _exercises[exerciseId];

              if (exercise == null) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        exercise.muscleGroup,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Divider(height: 24),
                      ...sets.map((set) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text('Set ${set.setNumber}'),
                            ),
                            Expanded(
                              child: Text(
                                '${set.reps} reps × ${set.weight}kg',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (set.notes != null)
                              Tooltip(
                                message: set.notes!,
                                child: const Icon(Icons.note, size: 16),
                              ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _editWorkout() async {
    final nameController = TextEditingController(text: _workout!.name);
    final notesController = TextEditingController(text: _workout!.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Workout Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedWorkout = Workout(
        id: _workout!.id,
        date: _workout!.date,
        name: nameController.text,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );
      await DatabaseHelper.instance.updateWorkout(updatedWorkout);
      _loadWorkout();
    }

    nameController.dispose();
    notesController.dispose();
  }

  Future<void> _deleteWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteWorkout(widget.workoutId);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}