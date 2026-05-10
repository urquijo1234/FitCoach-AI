# Plan de implementación — Fase 1 (FitCoach AI)

## Objetivo
Preparar la base técnica del MVP con configuración inicial de dependencias, estructura del proyecto y modelos de datos principales.

## Entregables de la Fase 1

### 1) Configuración de `pubspec.yaml` (Sección 1.4)
- Definir nombre del paquete y restricciones mínimas de SDK Dart 3.4+.
- Agregar dependencias obligatorias:
  - `provider`
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `http`
  - `flutter_dotenv`
- Agregar `flutter_test` en `dev_dependencies`.
- Mantener `uses-material-design: true`.

### 2) Estructura de directorios en `lib/` (Sección 2.1)
Crear la estructura base con archivos placeholder para permitir implementación incremental por capas:
- `models/`
- `providers/`
- `services/`
- `screens/`
- `widgets/`
- `utils/`
- `main.dart`

### 3) Modelos Dart según esquemas JSON (Sección 3)
Implementar:
- `lib/models/user_profile.dart`
  - Clase `UserProfile`
  - Constructor requerido
  - `fromJson`, `toJson`, `copyWith`
- `lib/models/weekly_plan.dart`
  - Clases `WeeklyPlan`, `Diet`, `Macros`, `Meal`, `TrainingDay`, `Exercise`
  - `fromJson` y `toJson` en todas las clases
  - `copyWith` en `WeeklyPlan`
  - Campo mutable `completed` en `Exercise`

## Criterios de aceptación
- `pubspec.yaml` contiene dependencias mínimas de la sección 1.4.
- Existe la estructura exacta de carpetas y archivos de la sección 2.1.
- Los modelos serializan/deserializan usando las llaves JSON definidas (`snake_case`).
- `UserProfile` y `WeeklyPlan` implementan `copyWith`.

## Riesgos y decisiones técnicas
- En la especificación se usa `^latest` para Firebase; se fijan versiones mayores estables (`^3`, `^5`) para evitar errores de resolución semántica.
- Los timestamps están serializados como ISO-8601 (`String`) para pruebas unitarias y compatibilidad inicial; en capa Firestore podrá mapearse a `Timestamp`.

## Próximo paso (Fase 2 sugerida)
- Implementar `PromptBuilder`, servicios (`AuthService`, `FirestoreService`, `LLMService`) y pruebas unitarias obligatorias.
