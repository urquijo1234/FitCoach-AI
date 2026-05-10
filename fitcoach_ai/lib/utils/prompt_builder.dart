import 'package:fitcoach_ai/models/user_profile.dart';

class PromptBuilder {
  static const String systemPrompt = '''Eres un coach profesional de gimnasio y nutricionista deportivo certificado.
Tu ÚNICA tarea es generar un plan semanal de alimentación y entrenamiento.
DEBES responder EXCLUSIVAMENTE con un objeto JSON válido.
NO incluyas texto adicional, explicaciones, disculpas ni bloques de código markdown.
NO envuelvas la respuesta en ```json``` ni en ningún otro marcador.
La respuesta debe ser ÚNICAMENTE el objeto JSON, comenzando con { y terminando con }.''';


  static UserProfile _sanitizeProfile(UserProfile profile) {
    return UserProfile(
      uid: profile.uid,
      age: profile.age,
      gender: _safeValue(profile.gender, fallback: 'No especificado'),
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      goal: _safeValue(profile.goal, fallback: 'Mantenimiento'),
      trainingDaysPerWeek: profile.trainingDaysPerWeek,
      allergies: profile.allergies
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      injuries: profile.injuries
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      completedOnboarding: profile.completedOnboarding,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  static String _safeValue(String? value, {required String fallback}) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? fallback : trimmed;
  }

  static String buildUserPrompt(UserProfile profile) {
    final safeProfile = _sanitizeProfile(profile);
    final allergies = safeProfile.allergies.isEmpty ? 'Ninguna' : safeProfile.allergies.join(', ');
    final injuries = safeProfile.injuries.isEmpty ? 'Ninguna' : safeProfile.injuries.join(', ');

    return '''Genera un plan semanal para el siguiente perfil:
- Edad: ${safeProfile.age} años
- Género: ${safeProfile.gender}
- Peso: ${safeProfile.weightKg} kg
- Altura: ${safeProfile.heightCm} cm
- Objetivo: ${safeProfile.goal}
- Días de entrenamiento por semana: ${safeProfile.trainingDaysPerWeek}
- Alergias alimentarias: $allergies
- Lesiones o limitaciones físicas: $injuries

Responde con un JSON que siga EXACTAMENTE esta estructura:
{
  "diet": {
    "daily_calories": <int>,
    "macros": {
      "protein_g": <int>,
      "carbs_g": <int>,
      "fat_g": <int>
    },
    "meals": [
      {
        "name": "<string>",
        "description": "<string>",
        "calories": <int>
      }
    ]
  },
  "training_days": [
    {
      "day_index": <int 1-7>,
      "day_label": "<string>",
      "muscle_group": "<string>",
      "exercises": [
        {
          "exercise_id": "<string único>",
          "name": "<string>",
          "sets": <int>,
          "reps": "<string>",
          "rest_seconds": <int>,
          "completed": false
        }
      ]
    }
  ]
}

REGLAS:
- "meals" DEBE contener exactamente 5 comidas (Desayuno, Media Mañana, Almuerzo, Merienda, Cena).
- "training_days" DEBE contener exactamente ${safeProfile.trainingDaysPerWeek} elementos.
- Cada día DEBE tener entre 5 y 8 ejercicios.
- Los ejercicios DEBEN respetar las lesiones indicadas.
- Las comidas NO DEBEN incluir ingredientes que coincidan con las alergias.
- "completed" siempre DEBE ser false.''';
  }
}
