import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/exercise.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<Exercise> _exercises = [];
  List<String> _muscleGroups = [];
  String? _selectedMuscleGroup;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final muscleGroups = await DatabaseHelper.instance.getMuscleGroups();
    final exercises = await DatabaseHelper.instance.getExercises(
      muscleGroup: _selectedMuscleGroup,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    setState(() {
      _muscleGroups = muscleGroups;
      _exercises = exercises;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _loadData();
                  },
                ),
              ),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedMuscleGroup == null,
                      onSelected: (selected) {
                        setState(() => _selectedMuscleGroup = null);
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._muscleGroups.map((group) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(group),
                        selected: _selectedMuscleGroup == group,
                        onSelected: (selected) {
                          setState(() => _selectedMuscleGroup = selected ? group : null);
                          _loadData();
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? const Center(child: Text('No exercises found'))
              : ListView.builder(
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(exercise.muscleGroup[0]),
                        ),
                        title: Text(exercise.name),
                        subtitle: Text('${exercise.muscleGroup} • ${exercise.difficulty}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showExerciseDetails(exercise),
                      ),
                    );
                  },
                ),
    );
  }

  void _showExerciseDetails(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Chip(label: Text(exercise.muscleGroup)),
                const SizedBox(height: 8),
                Chip(label: Text(exercise.difficulty)),
                const SizedBox(height: 16),
                Text('Description', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(exercise.description ?? 'No description available'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
