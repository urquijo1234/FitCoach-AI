import 'package:fitcoach_ai/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('DEBE parsear correctamente un perfil completo', () {
      final profile = UserProfile.fromJson({
        'uid': 'abc123',
        'email': 'test@example.com',
        'age': 25,
        'gender': 'masculino',
        'weight_kg': 80.0,
        'height_cm': 175.0,
        'goal': 'volumen',
        'training_days_per_week': 5,
        'allergies': ['Maní', 'Mariscos'],
        'injuries': ['Rodilla izquierda'],
        'onboarding_completed': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      expect(profile.uid, 'abc123');
      expect(profile.age, 25);
      expect(profile.weightKg, 80.0);
      expect(profile.allergies, contains('Maní'));
      expect(profile.injuries.length, 1);
      expect(profile.onboardingCompleted, isTrue);
    });
  });
}
