import 'package:fitcoach_ai/models/weekly_plan.dart';
import 'package:fitcoach_ai/providers/user_profile_provider.dart';
import 'package:fitcoach_ai/providers/weekly_plan_provider.dart';
import 'package:fitcoach_ai/widgets/exercise_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DailyRoutineScreen extends StatelessWidget {
  const DailyRoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeeklyPlanProvider>();

    if (provider.isLoading && provider.weeklyPlan == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.errorMessage != null && provider.weeklyPlan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rutina de Hoy')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.errorMessage!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final profileProvider = context.read<UserProfileProvider>();
                  final userProfile = profileProvider.profile;
                  if (userProfile == null) return;
                  await context.read<WeeklyPlanProvider>().generatePlan(userProfile);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final plan = provider.weeklyPlan;
    final dayIndex = DateTime.now().weekday;
    final today = plan == null ? null : _findToday(plan, dayIndex);

    return Scaffold(
      appBar: AppBar(title: const Text('Rutina de Hoy')),
      body: today == null || today.exercises.isEmpty
          ? const Center(child: Text('Día de Descanso'))
          : _RoutineList(day: today),
    );
  }
}

TrainingDay? _findToday(WeeklyPlan plan, int dayIndex) {
  for (final day in plan.trainingDays) {
    if (day.dayIndex == dayIndex) return day;
  }
  return null;
}

class _RoutineList extends StatelessWidget {
  const _RoutineList({required this.day});

  final TrainingDay day;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WeeklyPlanProvider>();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: day.exercises.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('${day.dayLabel} • ${day.muscleGroup}', style: Theme.of(context).textTheme.titleLarge),
          );
        }
        final exercise = day.exercises[index - 1];
        return ExerciseCard(
          exercise: exercise,
          onChanged: (value) {
            if (value == null) return;
            provider.updateExerciseCompletion(day.dayIndex, exercise.exerciseId, value);
          },
        );
      },
    );
  }
}
