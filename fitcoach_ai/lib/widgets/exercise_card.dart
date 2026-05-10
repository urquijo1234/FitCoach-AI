import 'package:fitcoach_ai/models/weekly_plan.dart';
import 'package:flutter/material.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onChanged,
  });

  final Exercise exercise;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: exercise.completed,
        onChanged: onChanged,
        title: Text(exercise.name),
        subtitle: Text('${exercise.sets} series • ${exercise.reps} • descanso ${exercise.restSeconds}s'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
