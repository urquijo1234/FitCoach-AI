import 'package:fitcoach_ai/models/user_profile.dart';
import 'package:fitcoach_ai/models/weekly_plan.dart';
import 'package:fitcoach_ai/services/firestore_service.dart';
import 'package:fitcoach_ai/services/llm_service.dart';
import 'package:flutter/material.dart';

class WeeklyPlanProvider extends ChangeNotifier {
  WeeklyPlanProvider({FirestoreService? firestoreService, LLMService? llmService})
      : _firestoreService = firestoreService ?? FirestoreService(),
        _llmService = llmService ?? LLMService();

  final FirestoreService _firestoreService;
  final LLMService _llmService;

  WeeklyPlan? _weeklyPlan;
  bool _isLoading = false;
  String? _errorMessage;

  WeeklyPlan? get weeklyPlan => _weeklyPlan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> generatePlan(UserProfile profile) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final weekLabel = _isoWeekLabel(DateTime.now().toUtc());
      final planId = '${profile.uid}_$weekLabel';
      _weeklyPlan = await _firestoreService.getWeeklyPlan(planId);
      if (_weeklyPlan == null) {
        _weeklyPlan = await _llmService.generateWeeklyPlan(profile);
        await _firestoreService.saveWeeklyPlan(_weeklyPlan!);
      }
    } on Exception catch (error, stackTrace) {
      debugPrint('WeeklyPlanProvider.generatePlan error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = 'No se pudo obtener/generar el plan semanal (IA/Firestore)';
      _weeklyPlan = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateExerciseCompletion(
      int dayIndex, String exerciseId, bool completed) async {
    if (_weeklyPlan == null) return;

    try {
      await _firestoreService.updateExerciseCompletion(
        _weeklyPlan!.planId,
        dayIndex,
        exerciseId,
        completed,
      );

      final updatedDays = _weeklyPlan!.trainingDays.map((day) {
        if (day.dayIndex != dayIndex) return day;
        final updatedExercises = day.exercises.map((exercise) {
          if (exercise.exerciseId == exerciseId) {
            exercise.completed = completed;
          }
          return exercise;
        }).toList();
        return TrainingDay(
          dayIndex: day.dayIndex,
          dayLabel: day.dayLabel,
          muscleGroup: day.muscleGroup,
          exercises: updatedExercises,
        );
      }).toList();

      _weeklyPlan = _weeklyPlan!.copyWith(trainingDays: updatedDays);
      notifyListeners();
    } catch (_) {
      _errorMessage = 'No se pudo actualizar el ejercicio';
      notifyListeners();
    }
  }


  Future<void> loadOrGenerateWeeklyPlan(UserProfile profile) async => generatePlan(profile);

  String _isoWeekLabel(DateTime date) {
    final target = date.add(Duration(days: 4 - (date.weekday == 7 ? 7 : date.weekday)));
    final firstThursday = DateTime.utc(target.year, 1, 4);
    final firstWeekStart = firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
    final currentWeekStart = target.subtract(Duration(days: target.weekday - 1));
    final weekNumber = ((currentWeekStart.difference(firstWeekStart).inDays) / 7).floor() + 1;
    return '${target.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}
