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
          ? const _ActiveRecoveryView()
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: day.exercises.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
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
          onChanged: (value) async {
            if (value == null) return;
            await provider.updateExerciseCompletion(day.dayIndex, exercise.exerciseId, value);
          },
        );
      },
    );
  }
}

class _ActiveRecoveryView extends StatelessWidget {
  const _ActiveRecoveryView();

  @override
  Widget build(BuildContext context) {
    final tips = [
      ('Movilidad de cadera', '2 series de 60 segundos'),
      ('Estiramiento de espalda', '2 series de 45 segundos'),
      ('Caminata ligera', '20 a 30 minutos a ritmo suave'),
      ('Respiración diafragmática', '5 minutos para recuperación'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Text('Active Recovery', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Hoy toca recuperación activa. Mantén el cuerpo en movimiento sin sobrecargarlo.'),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: tips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tip = tips[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.self_improvement),
                    title: Text(tip.$1),
                    subtitle: Text(tip.$2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
