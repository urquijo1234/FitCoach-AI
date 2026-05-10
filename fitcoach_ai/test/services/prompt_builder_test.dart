import 'package:fitcoach_ai/models/user_profile.dart';
import 'package:fitcoach_ai/utils/prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromptBuilder', () {
    test('DEBE incluir todos los datos del perfil en el prompt generado', () {
      final profile = UserProfile.fromJson({
        'uid': 'test',
        'email': 'test@test.com',
        'age': 22,
        'gender': 'masculino',
        'weight_kg': 75.0,
        'height_cm': 178.0,
        'goal': 'volumen',
        'training_days_per_week': 4,
        'allergies': ['Gluten', 'Lácteos'],
        'injuries': ['Hombro derecho'],
        'onboarding_completed': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final prompt = PromptBuilder.buildUserPrompt(profile);
      expect(prompt, contains('22'));
      expect(prompt, contains('masculino'));
      expect(prompt, contains('75.0'));
      expect(prompt, contains('178.0'));
      expect(prompt, contains('volumen'));
      expect(prompt, contains('4'));
      expect(prompt, contains('Gluten'));
      expect(prompt, contains('Lácteos'));
      expect(prompt, contains('Hombro derecho'));
    });

    test('DEBE mostrar Ninguna cuando alergias y lesiones están vacías', () {
      final profile = UserProfile.fromJson({
        'uid': 'test',
        'email': 'test@test.com',
        'age': 30,
        'gender': 'femenino',
        'weight_kg': 65.0,
        'height_cm': 160.0,
        'goal': 'mantenimiento',
        'training_days_per_week': 3,
        'allergies': [],
        'injuries': [],
        'onboarding_completed': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final prompt = PromptBuilder.buildUserPrompt(profile);
      expect(prompt, contains('Ninguna'));
    });
  });
}
