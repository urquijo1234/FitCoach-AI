import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcoach_ai/models/user_profile.dart';
import 'package:fitcoach_ai/models/weekly_plan.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _weeklyPlans => _firestore.collection('weekly_plans');

  Future<void> saveUserProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(profile.toJson(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromJson(doc.data()!);
  }

  Future<void> saveWeeklyPlan(WeeklyPlan plan) async {
    await _weeklyPlans.doc(plan.planId).set(plan.toJson(), SetOptions(merge: true));
  }

  Future<WeeklyPlan?> getWeeklyPlan(String planId) async {
    final doc = await _weeklyPlans.doc(planId).get();
    if (!doc.exists || doc.data() == null) return null;
    return WeeklyPlan.fromJson(doc.data()!);
  }

  Future<void> updateExerciseCompletion(
    String planId,
    int dayIndex,
    String exerciseId,
    bool completed,
  ) async {
    final docRef = _weeklyPlans.doc(planId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Weekly plan no encontrado: $planId');
      }

      final data = snapshot.data()!;
      final trainingDays = List<Map<String, dynamic>>.from(
        (data['training_days'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      final dayPos = trainingDays.indexWhere((day) => day['day_index'] == dayIndex);
      if (dayPos == -1) throw StateError('Día no encontrado: $dayIndex');

      final exercises = List<Map<String, dynamic>>.from(
        (trainingDays[dayPos]['exercises'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );

      final exercisePos = exercises.indexWhere((exercise) => exercise['exercise_id'] == exerciseId);
      if (exercisePos == -1) throw StateError('Ejercicio no encontrado: $exerciseId');

      transaction.update(docRef, {
        'training_days.$dayPos.exercises.$exercisePos.completed': completed,
      });
    });
  }
}
