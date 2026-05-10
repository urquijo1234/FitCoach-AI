import 'package:fitcoach_ai/models/weekly_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyPlan.fromJson', () {
    final mockLLMResponse = {
      'diet': {
        'daily_calories': 2500,
        'macros': {'protein_g': 180, 'carbs_g': 280, 'fat_g': 75},
        'meals': [
          {'name': 'Desayuno', 'description': 'Avena con plátano, miel y nueces', 'calories': 500},
          {'name': 'Media Mañana', 'description': 'Yogur griego con frutos rojos', 'calories': 300},
          {'name': 'Almuerzo', 'description': 'Pechuga de pollo con arroz integral y brócoli', 'calories': 700},
          {'name': 'Merienda', 'description': 'Batido de proteína con avena', 'calories': 400},
          {'name': 'Cena', 'description': 'Salmón al horno con ensalada mixta', 'calories': 600},
        ],
      },
      'training_days': [
        {
          'day_index': 1,
          'day_label': 'Lunes',
          'muscle_group': 'Pecho y Tríceps',
          'exercises': [
            {'exercise_id': 'ex_001', 'name': 'Press de banca', 'sets': 4, 'reps': '8-12', 'rest_seconds': 90, 'completed': false},
            {'exercise_id': 'ex_002', 'name': 'Aperturas con mancuernas', 'sets': 3, 'reps': '12-15', 'rest_seconds': 60, 'completed': false},
          ],
        }
      ],
    };

    test('DEBE parsear correctamente un JSON válido del LLM', () {
      final plan = WeeklyPlan.fromJson({
        'plan_id': 'test_uid_2026-W19',
        'uid': 'test_uid',
        'generated_at': DateTime.now().toIso8601String(),
        'week_label': '2026-W19',
        ...mockLLMResponse,
      });

      expect(plan.diet.dailyCalories, equals(2500));
      expect(plan.diet.macros.proteinG, equals(180));
      expect(plan.diet.macros.carbsG, equals(280));
      expect(plan.diet.macros.fatG, equals(75));
      expect(plan.diet.meals.length, equals(5));
      expect(plan.diet.meals[0].name, equals('Desayuno'));
      expect(plan.trainingDays.length, equals(1));
      expect(plan.trainingDays[0].dayLabel, equals('Lunes'));
      expect(plan.trainingDays[0].muscleGroup, equals('Pecho y Tríceps'));
      expect(plan.trainingDays[0].exercises.length, equals(2));
      expect(plan.trainingDays[0].exercises[0].name, equals('Press de banca'));
      expect(plan.trainingDays[0].exercises[0].sets, equals(4));
      expect(plan.trainingDays[0].exercises[0].completed, isFalse);
    });

    test('DEBE tener todos los ejercicios con completed == false', () {
      final plan = WeeklyPlan.fromJson({
        'plan_id': 'test_uid_2026-W19',
        'uid': 'test_uid',
        'generated_at': DateTime.now().toIso8601String(),
        'week_label': '2026-W19',
        ...mockLLMResponse,
      });

      for (final day in plan.trainingDays) {
        for (final exercise in day.exercises) {
          expect(exercise.completed, isFalse);
        }
      }
    });
  });
}
