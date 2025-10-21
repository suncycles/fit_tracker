import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';


class NewWorkoutScreen extends StatefulWidget {
  const NewWorkoutScreen({super.key});

  @override
  State<NewWorkoutScreen> createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends State<NewWorkoutScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final List<ExerciseInWorkout> _selectedExercises = [];
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Workout'),
        actions: [
          TextButton(
            onPressed: _selectedExercises.isEmpty ? null : _saveWorkout,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Workout Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Exercises', style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedExercises.isEmpty
                ? const Center(child: Text('No exercises added yet'))
                : ReorderableListView.builder(
                    itemCount: _selectedExercises.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _selectedExercises.removeAt(oldIndex);
                        _selectedExercises.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _selectedExercises[index];
                      return Card(
                        key: ValueKey(item.exercise.id),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ExpansionTile(
                          leading: const Icon(Icons.drag_handle),
                          title: Text(item.exercise.name),
                          subtitle: Text('${item.sets.length} sets'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() => _selectedExercises.removeAt(index));
                            },
                          ),
                          children: [
                            ...item.sets.asMap().entries.map((entry) {
                              final setIndex = entry.key;
                              final set = entry.value;
                              return ListTile(
                                dense: true,
                                title: Row(
                                  children: [
                                    Text('Set ${setIndex + 1}: '),
                                    Expanded(
                                      child: Text(
                                        '${set.reps} reps @ ${set.weight}kg',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editSet(index, setIndex),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () {
                                        setState(() => item.sets.removeAt(setIndex));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextButton.icon(
                                onPressed: () => _addSet(index),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Set'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addExercise() async {
    final exercises = await DatabaseHelper.instance.getExercises();
    if (!mounted) return;

    final selected = await showDialog<Exercise>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Exercise'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                title: Text(exercise.name),
                subtitle: Text(exercise.muscleGroup),
                onTap: () => Navigator.pop(context, exercise),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedExercises.add(ExerciseInWorkout(exercise: selected, sets: []));
      });
    }
  }

  Future<void> _addSet(int exerciseIndex) async {
    final set = await _showSetDialog();
    if (set != null) {
      setState(() {
        _selectedExercises[exerciseIndex].sets.add(set);
      });
    }
  }

  Future<void> _editSet(int exerciseIndex, int setIndex) async {
    final currentSet = _selectedExercises[exerciseIndex].sets[setIndex];
    final set = await _showSetDialog(initialSet: currentSet);
    if (set != null) {
      setState(() {
        _selectedExercises[exerciseIndex].sets[setIndex] = set;
      });
    }
  }

  Future<SetData?> _showSetDialog({SetData? initialSet}) async {
    final repsController = TextEditingController(text: initialSet?.reps.toString() ?? '');
    final weightController = TextEditingController(text: initialSet?.weight.toString() ?? '');
    final notesController = TextEditingController(text: initialSet?.notes ?? '');

    return showDialog<SetData>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initialSet == null ? 'Add Set' : 'Edit Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final reps = int.tryParse(repsController.text);
              final weight = double.tryParse(weightController.text);
              if (reps != null && weight != null) {
                Navigator.pop(
                  context,
                  SetData(
                    reps: reps,
                    weight: weight,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  ),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkout() async {
    if (_selectedExercises.isEmpty) return;

    final name = _nameController.text.isEmpty ? 'Workout' : _nameController.text;
    final notes = _notesController.text.isEmpty ? null : _notesController.text;

    final workout = Workout(
      date: _selectedDate.toIso8601String(),
      name: name,
      notes: notes,
    );

    final workoutId = await DatabaseHelper.instance.createWorkout(workout);

    for (var exerciseItem in _selectedExercises) {
      for (var i = 0; i < exerciseItem.sets.length; i++) {
        final setData = exerciseItem.sets[i];
        final workoutSet = WorkoutSet(
          workoutId: workoutId,
          exerciseId: exerciseItem.exercise.id!,
          setNumber: i + 1,
          reps: setData.reps,
          weight: setData.weight,
          notes: setData.notes,
        );
        await DatabaseHelper.instance.createWorkoutSet(workoutSet);
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class ExerciseInWorkout {
  final Exercise exercise;
  final List<SetData> sets;

  ExerciseInWorkout({required this.exercise, required this.sets});
}

class SetData {
  final int reps;
  final double weight;
  final String? notes;

  SetData({required this.reps, required this.weight, this.notes});
}
