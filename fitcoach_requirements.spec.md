# FitCoach AI — Especificación Técnica del MVP

> **Versión:** 1.0.0  
> **Fecha:** 2026-05-08  
> **Metodología:** Spec Driven Development (SDD)  
> **Audiencia:** Asistente de código IA (Cursor, Copilot) y desarrolladores humanos.  
> **Regla cardinal:** Toda funcionalidad NO descrita explícitamente en este documento queda FUERA del alcance del MVP. No se debe implementar nada que no esté aquí especificado.

---

## 1. Visión General

### 1.1 Propósito

FitCoach AI es una aplicación móvil que actúa como coach de gimnasio personalizado. La app recopila el perfil físico y los objetivos del usuario, se conecta a la API de un LLM para generar un plan semanal (alimentación + rutina de ejercicios) y permite al usuario interactuar con la rutina diaria marcando ejercicios completados en tiempo real.

### 1.2 Alcance del MVP

El MVP contempla exactamente cuatro vistas funcionales (Auth, Onboarding, Dashboard, Rutina Diaria), un ciclo de generación semanal vía LLM, persistencia en Firestore y un conjunto mínimo de pruebas unitarias.

### 1.3 Stack Tecnológico

| Capa | Tecnología | Versión mínima |
|---|---|---|
| Framework móvil | Flutter | 3.22+ |
| Lenguaje | Dart | 3.4+ |
| Gestión de estado | Provider (`provider`) | 6.x |
| Autenticación | Firebase Authentication | latest |
| Base de datos | Cloud Firestore | latest |
| Llamadas HTTP | `http` (paquete Dart) | 1.x |
| Variables de entorno | `flutter_dotenv` | 5.x |
| Motor IA | API REST de LLM (Gemini o OpenAI) | — |
| Testing | `flutter_test` (SDK) | — |

### 1.4 Dependencias del `pubspec.yaml`

El archivo `pubspec.yaml` DEBE incluir, como mínimo, las siguientes dependencias:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  http: ^1.0.0
  flutter_dotenv: ^5.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

## 2. Arquitectura

### 2.1 Estructura de Directorios

El proyecto DEBE seguir la siguiente estructura de carpetas dentro de `lib/`:

```
lib/
├── main.dart
├── models/
│   ├── user_profile.dart
│   └── weekly_plan.dart
├── providers/
│   ├── auth_provider.dart
│   ├── user_profile_provider.dart
│   └── weekly_plan_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── llm_service.dart
├── screens/
│   ├── auth_screen.dart
│   ├── onboarding_screen.dart
│   ├── dashboard_screen.dart
│   └── daily_routine_screen.dart
├── widgets/
│   ├── exercise_card.dart
│   ├── macro_summary_card.dart
│   └── meal_card.dart
└── utils/
    ├── constants.dart
    └── prompt_builder.dart
```

### 2.2 Diagrama de Capas

```
┌─────────────────────────────────────┐
│            SCREENS (UI)             │
│  auth · onboarding · dashboard ·   │
│  daily_routine                      │
├─────────────────────────────────────┤
│          PROVIDERS (Estado)         │
│  AuthProvider · UserProfileProvider │
│  WeeklyPlanProvider                 │
├─────────────────────────────────────┤
│          SERVICES (Lógica)          │
│  AuthService · FirestoreService ·   │
│  LLMService                        │
├─────────────────────────────────────┤
│         MODELOS (Datos)             │
│  UserProfile · WeeklyPlan ·        │
│  DayPlan · Exercise · Meal         │
├─────────────────────────────────────┤
│      INFRAESTRUCTURA EXTERNA        │
│  Firebase Auth · Firestore · LLM   │
└─────────────────────────────────────┘
```

### 2.3 Flujo de Datos

1. El usuario se autentica vía `AuthService` → Firebase Auth.
2. Al completar el onboarding, `UserProfileProvider` persiste el perfil en Firestore a través de `FirestoreService`.
3. El `WeeklyPlanProvider` verifica si existe un plan vigente (generado en la semana actual). Si no existe, invoca `LLMService`.
4. `LLMService` construye el prompt (via `PromptBuilder`), envía la solicitud HTTP al LLM, parsea el JSON de respuesta y devuelve un objeto `WeeklyPlan`.
5. El plan se almacena en Firestore. Las interacciones del usuario (checkboxes) se escriben en tiempo real en el subdocumento correspondiente.

---

## 3. Modelo de Datos (Esquemas)

### 3.1 Colección `users`

Ruta en Firestore: `users/{uid}`

El documento DEBE contener exactamente los siguientes campos:

```json
{
  "uid": "string — UID de Firebase Auth, clave primaria",
  "email": "string — correo electrónico del usuario",
  "age": "int — edad en años, rango válido: 14–80",
  "gender": "string — uno de: 'masculino', 'femenino', 'otro'",
  "weight_kg": "double — peso en kilogramos, rango válido: 30.0–250.0",
  "height_cm": "double — altura en centímetros, rango válido: 100.0–230.0",
  "goal": "string — uno de: 'volumen', 'definicion', 'mantenimiento', 'perdida_de_peso', 'resistencia'",
  "training_days_per_week": "int — rango válido: 3–6",
  "allergies": ["string — lista de alergias, puede estar vacía"],
  "injuries": ["string — lista de lesiones, puede estar vacía"],
  "onboarding_completed": "bool — true cuando el formulario ha sido enviado",
  "created_at": "Timestamp — fecha de creación del documento",
  "updated_at": "Timestamp — fecha de última modificación"
}
```

**Clase Dart correspondiente — `lib/models/user_profile.dart`:**

```dart
class UserProfile {
  final String uid;
  final String email;
  final int age;
  final String gender;
  final double weightKg;
  final double heightCm;
  final String goal;
  final int trainingDaysPerWeek;
  final List<String> allergies;
  final List<String> injuries;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // DEBE implementar:
  // - Constructor con parámetros requeridos.
  // - factory UserProfile.fromJson(Map<String, dynamic> json)
  // - Map<String, dynamic> toJson()
  // - método copyWith(...)
}
```

### 3.2 Colección `weekly_plans`

Ruta en Firestore: `weekly_plans/{planId}`

Cada documento representa el plan completo de una semana para un usuario. El campo `planId` se DEBE generar como `{uid}_{iso_week}` donde `iso_week` tiene formato `YYYY-Www` (ej. `2026-W19`).

```json
{
  "plan_id": "string — '{uid}_{YYYY-Www}'",
  "uid": "string — referencia al UID del usuario",
  "generated_at": "Timestamp — momento de generación",
  "week_label": "string — 'YYYY-Www'",
  "diet": {
    "daily_calories": "int — calorías diarias objetivo",
    "macros": {
      "protein_g": "int — gramos de proteína diarios",
      "carbs_g": "int — gramos de carbohidratos diarios",
      "fat_g": "int — gramos de grasa diarios"
    },
    "meals": [
      {
        "name": "string — ej. 'Desayuno'",
        "description": "string — descripción del plato",
        "calories": "int — calorías aproximadas de la comida"
      }
    ]
  },
  "training_days": [
    {
      "day_index": "int — 1 a 7 (Lunes a Domingo)",
      "day_label": "string — ej. 'Lunes'",
      "muscle_group": "string — ej. 'Pecho y Tríceps'",
      "exercises": [
        {
          "exercise_id": "string — identificador único del ejercicio dentro del plan",
          "name": "string — nombre del ejercicio",
          "sets": "int — número de series",
          "reps": "string — repeticiones (puede ser rango: '8-12')",
          "rest_seconds": "int — descanso entre series en segundos",
          "completed": "bool — estado de completado, por defecto false"
        }
      ]
    }
  ]
}
```

**Clases Dart correspondientes — `lib/models/weekly_plan.dart`:**

```dart
class WeeklyPlan {
  final String planId;
  final String uid;
  final DateTime generatedAt;
  final String weekLabel;
  final Diet diet;
  final List<TrainingDay> trainingDays;

  // DEBE implementar: fromJson, toJson, copyWith
}

class Diet {
  final int dailyCalories;
  final Macros macros;
  final List<Meal> meals;

  // DEBE implementar: fromJson, toJson
}

class Macros {
  final int proteinG;
  final int carbsG;
  final int fatG;

  // DEBE implementar: fromJson, toJson
}

class Meal {
  final String name;
  final String description;
  final int calories;

  // DEBE implementar: fromJson, toJson
}

class TrainingDay {
  final int dayIndex;
  final String dayLabel;
  final String muscleGroup;
  final List<Exercise> exercises;

  // DEBE implementar: fromJson, toJson
}

class Exercise {
  final String exerciseId;
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  bool completed;

  // DEBE implementar: fromJson, toJson
  // NOTA: 'completed' es mutable para permitir actualizaciones en UI.
}
```

### 3.3 Reglas de Seguridad de Firestore

El archivo `firestore.rules` DEBE contener las siguientes reglas:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /weekly_plans/{planId} {
      allow read: if request.auth != null && resource.data.uid == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.uid == request.auth.uid;
      allow update: if request.auth != null && resource.data.uid == request.auth.uid;
      allow delete: if false;
    }
  }
}
```

---

## 4. Flujo UI

### 4.1 Mapa de Navegación

```
App Launch
  │
  ├─ Usuario NO autenticado ──► AuthScreen
  │                                │
  │                          Login/Registro exitoso
  │                                │
  │                                ▼
  │                    ┌─ onboarding_completed == false ──► OnboardingScreen
  │                    │                                         │
  │                    │                                   Envío exitoso
  │                    │                                         │
  ├─ Usuario autenticado ──────────────────────────────────────► DashboardScreen
  │                                                              │
  │                                                     "Ver Rutina de Hoy"
  │                                                              │
  │                                                              ▼
  │                                                      DailyRoutineScreen
  │
  └─ Logout ──► AuthScreen
```

### 4.2 Pantalla: AuthScreen (`lib/screens/auth_screen.dart`)

**Propósito:** Permitir al usuario registrarse o iniciar sesión con correo y contraseña.

**Elementos de UI obligatorios:**
- Campo de texto para correo electrónico con validación de formato (regex de email).
- Campo de texto para contraseña con visibilidad toggle (ícono de ojo). Mínimo 6 caracteres.
- Botón primario que alterna su texto entre "Iniciar Sesión" y "Registrarse".
- Enlace de texto inferior que alterna el modo: "¿No tienes cuenta? Regístrate" / "¿Ya tienes cuenta? Inicia sesión".
- Indicador de carga (`CircularProgressIndicator`) durante la operación asíncrona.
- `SnackBar` para errores de autenticación con mensajes legibles (no códigos Firebase crudos).

**Comportamiento:**
- Al autenticarse exitosamente, el sistema DEBE consultar Firestore para verificar si `onboarding_completed == true`.
- Si `onboarding_completed == false` o no existe documento, navegar a `OnboardingScreen`.
- Si `onboarding_completed == true`, navegar a `DashboardScreen`.
- La navegación post-auth DEBE usar `Navigator.pushReplacementNamed` para impedir retroceso a la pantalla de auth.

### 4.3 Pantalla: OnboardingScreen (`lib/screens/onboarding_screen.dart`)

**Propósito:** Recopilar el perfil físico y objetivos del usuario una sola vez.

**Elementos de UI obligatorios:**
- Campo numérico para Edad (`int`, validación: 14–80).
- Selector desplegable (`DropdownButtonFormField`) para Género: opciones `['Masculino', 'Femenino', 'Otro']`.
- Campo numérico con decimal para Peso en kg (`double`, validación: 30.0–250.0).
- Campo numérico con decimal para Altura en cm (`double`, validación: 100.0–230.0).
- Selector desplegable para Objetivo: opciones `['Volumen', 'Definición', 'Mantenimiento', 'Pérdida de peso', 'Resistencia']`.
- Slider o selector numérico para Días de entrenamiento por semana (`int`, rango: 3–6).
- Campo de texto con chips/tags para Alergias. El usuario escribe y presiona Enter/botón para agregar. Cada chip tiene botón de eliminar. PUEDE estar vacío.
- Campo de texto con chips/tags para Lesiones. Misma mecánica que Alergias. PUEDE estar vacío.
- Botón "Guardar y Comenzar" habilitado solo cuando todos los campos obligatorios pasan validación.
- `Form` widget con `GlobalKey<FormState>` para validación integral.

**Comportamiento:**
- Al presionar el botón, el sistema DEBE:
  1. Validar el formulario completo.
  2. Crear/actualizar el documento `users/{uid}` en Firestore con `onboarding_completed: true`.
  3. Mostrar indicador de carga durante la escritura.
  4. Navegar a `DashboardScreen` con `pushReplacementNamed`.
- Esta pantalla NO se muestra nuevamente si `onboarding_completed == true`.

### 4.4 Pantalla: DashboardScreen (`lib/screens/dashboard_screen.dart`)

**Propósito:** Mostrar el plan semanal generado (dieta y resumen) y dar acceso a la rutina diaria.

**Elementos de UI obligatorios:**
- AppBar con título "FitCoach AI" y botón de Logout (ícono `Icons.logout`).
- Sección superior: Tarjeta de resumen de macros (`MacroSummaryCard`) mostrando calorías diarias, proteínas, carbohidratos y grasas.
- Sección media: Lista vertical de tarjetas de comida (`MealCard`) con nombre, descripción y calorías de cada comida.
- Sección inferior: Botón prominente "Ver Rutina de Hoy" que navega a `DailyRoutineScreen`.
- Estado de carga: `CircularProgressIndicator` centrado mientras se genera o carga el plan.
- Estado de error/retry: Componente descrito en la Sección 6.

**Comportamiento:**
- Al entrar en la pantalla, `WeeklyPlanProvider` DEBE:
  1. Calcular la semana ISO actual (`YYYY-Www`).
  2. Consultar Firestore por `weekly_plans/{uid}_{YYYY-Www}`.
  3. Si el documento existe y es válido, cargarlo y mostrarlo.
  4. Si el documento NO existe, invocar `LLMService.generateWeeklyPlan(userProfile)`.
  5. Al recibir respuesta exitosa, almacenar el `WeeklyPlan` en Firestore y actualizar la UI.
  6. Si la generación falla, mostrar el estado Retry (Sección 6).

### 4.5 Pantalla: DailyRoutineScreen (`lib/screens/daily_routine_screen.dart`)

**Propósito:** Mostrar los ejercicios del día actual como una lista interactiva con checkboxes.

**Elementos de UI obligatorios:**
- AppBar con título dinámico: `"{dayLabel} — {muscleGroup}"` (ej. "Lunes — Pecho y Tríceps").
- Botón de retroceso en AppBar para volver al Dashboard.
- `ListView.builder` de widgets `ExerciseCard`.
- Barra de progreso lineal (`LinearProgressIndicator`) en la parte superior que refleja `(ejercicios completados / total ejercicios)`.

**Widget `ExerciseCard` (`lib/widgets/exercise_card.dart`):**
- Checkbox a la izquierda.
- Nombre del ejercicio en texto principal.
- Subtítulo con formato: `"{sets} series × {reps} reps · {rest_seconds}s descanso"`.
- Al marcar/desmarcar el checkbox, el ejercicio DEBE aplicar tachado visual (estilo `TextDecoration.lineThrough`) y opacidad reducida (0.5).

**Comportamiento:**
- El sistema DEBE determinar el día actual (`DateTime.now().weekday`) y filtrar el `TrainingDay` correspondiente del `WeeklyPlan`.
- Si el día actual NO es un día de entrenamiento, la pantalla DEBE mostrar un mensaje centrado: "Hoy es día de descanso. ¡Recupérate!" con un ícono ilustrativo.
- Al cambiar el estado de un checkbox, el sistema DEBE actualizar el campo `completed` del ejercicio correspondiente en Firestore inmediatamente usando `FirestoreService.updateExerciseCompletion(planId, dayIndex, exerciseId, bool)`.
- La actualización en Firestore DEBE ser atómica: se actualiza solo el campo `training_days[dayIndex].exercises[exerciseIndex].completed`, no el documento completo.

---

## 5. Lógica de Integración LLM

### 5.1 Servicio LLM (`lib/services/llm_service.dart`)

**Responsabilidad única:** Construir el prompt, enviar la solicitud HTTP, parsear la respuesta JSON y devolver un objeto `WeeklyPlan`.

**Firma del método principal:**

```dart
Future<WeeklyPlan> generateWeeklyPlan(UserProfile profile) async { ... }
```

### 5.2 Construcción del Prompt (`lib/utils/prompt_builder.dart`)

El sistema DEBE construir un prompt compuesto por un System Prompt y un User Prompt.

**System Prompt (texto exacto que se DEBE usar):**

```
Eres un coach profesional de gimnasio y nutricionista deportivo certificado.
Tu ÚNICA tarea es generar un plan semanal de alimentación y entrenamiento.
DEBES responder EXCLUSIVAMENTE con un objeto JSON válido.
NO incluyas texto adicional, explicaciones, disculpas ni bloques de código markdown.
NO envuelvas la respuesta en ```json``` ni en ningún otro marcador.
La respuesta debe ser ÚNICAMENTE el objeto JSON, comenzando con { y terminando con }.
```

**User Prompt (plantilla dinámica):**

```
Genera un plan semanal para el siguiente perfil:
- Edad: {age} años
- Género: {gender}
- Peso: {weight_kg} kg
- Altura: {height_cm} cm
- Objetivo: {goal}
- Días de entrenamiento por semana: {training_days_per_week}
- Alergias alimentarias: {allergies (lista separada por comas, o "Ninguna")}
- Lesiones o limitaciones físicas: {injuries (lista separada por comas, o "Ninguna")}

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
- "training_days" DEBE contener exactamente {training_days_per_week} elementos.
- Cada día DEBE tener entre 5 y 8 ejercicios.
- Los ejercicios DEBEN respetar las lesiones indicadas.
- Las comidas NO DEBEN incluir ingredientes que coincidan con las alergias.
- "completed" siempre DEBE ser false.
```

### 5.3 Llamada HTTP

El servicio DEBE realizar una solicitud `POST` a la API del LLM configurada.

**Para OpenAI (`https://api.openai.com/v1/chat/completions`):**

```dart
final response = await http.post(
  Uri.parse(apiUrl),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  },
  body: jsonEncode({
    'model': modelName,       // ej. "gpt-4o-mini"
    'temperature': 0.7,
    'max_tokens': 4000,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ],
  }),
);
```

**Para Gemini (`https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`):**

```dart
final response = await http.post(
  Uri.parse('$apiUrl?key=$apiKey'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'contents': [
      {'parts': [{'text': '$systemPrompt\n\n$userPrompt'}]}
    ],
    'generationConfig': {
      'temperature': 0.7,
      'maxOutputTokens': 4000,
      'responseMimeType': 'application/json',
    },
  }),
);
```

**Variables de configuración requeridas en `.env`:**

```
LLM_PROVIDER=openai
LLM_API_KEY=sk-XXXXXXXXXXXXXXXX
LLM_MODEL=gpt-4o-mini
LLM_API_URL=https://api.openai.com/v1/chat/completions
```

El servicio DEBE leer el `LLM_PROVIDER` para determinar qué formato de request/response utilizar.

### 5.4 Parseo de Respuesta

El servicio DEBE:

1. Verificar que `response.statusCode == 200`. Si no, lanzar una excepción personalizada `LLMApiException`.
2. Extraer el contenido de texto de la respuesta según el proveedor:
   - OpenAI: `responseBody['choices'][0]['message']['content']`
   - Gemini: `responseBody['candidates'][0]['content']['parts'][0]['text']`
3. Limpiar el string resultante: eliminar posibles backticks de markdown (` ```json `, ` ``` `), trim de espacios.
4. Intentar `jsonDecode(cleanedString)`. Si falla, lanzar `LLMJsonParseException`.
5. Construir el objeto `WeeklyPlan` usando `WeeklyPlan.fromJson(decodedMap)`, enriqueciendo con `planId`, `uid`, `generatedAt` y `weekLabel`.
6. Validar que `trainingDays.length == profile.trainingDaysPerWeek`. Si no coincide, lanzar `LLMValidationException`.

### 5.5 Política de Generación

- La generación se DEBE ejecutar una sola vez por semana ISO.
- Antes de invocar al LLM, el provider DEBE consultar Firestore por el `planId` correspondiente a la semana actual.
- Si ya existe un plan para la semana actual, NO se debe invocar al LLM.
- No existe mecanismo de regeneración manual en el MVP.

---

## 6. Manejo de Errores y Seguridad

### 6.1 Excepciones Personalizadas

El sistema DEBE definir las siguientes excepciones en `lib/utils/constants.dart` o en un archivo dedicado `lib/utils/exceptions.dart`:

```dart
class LLMApiException implements Exception {
  final int statusCode;
  final String message;
  LLMApiException(this.statusCode, this.message);
}

class LLMJsonParseException implements Exception {
  final String rawResponse;
  LLMJsonParseException(this.rawResponse);
}

class LLMValidationException implements Exception {
  final String reason;
  LLMValidationException(this.reason);
}
```

### 6.2 UI de Reintento (Retry)

Cuando la generación del plan falle por cualquiera de las excepciones anteriores (o por timeout de red), la UI DEBE mostrar el siguiente estado en `DashboardScreen`:

- Ícono centrado: `Icons.sports_martial_arts` o equivalente, tamaño 64px, color primario con opacidad 0.6.
- Texto principal: **"El Coach está pensando..."**
- Texto secundario: "No pudimos generar tu plan. Verifica tu conexión e intenta de nuevo."
- Botón `ElevatedButton` con texto "Reintentar" que invoque nuevamente `WeeklyPlanProvider.generatePlan()`.
- El botón DEBE mostrar un `CircularProgressIndicator` dentro de sí mismo durante la carga (no se reemplaza toda la pantalla).
- Se DEBE implementar un máximo de 3 reintentos automáticos con backoff exponencial (2s, 4s, 8s) dentro de `LLMService` antes de propagar la excepción a la UI.

### 6.3 Manejo de Errores por Capa

| Capa | Error | Acción |
|---|---|---|
| `AuthService` | `FirebaseAuthException` | Mapear códigos Firebase a mensajes en español y mostrar en `SnackBar`. Mapeo mínimo: `wrong-password` → "Contraseña incorrecta", `user-not-found` → "No existe una cuenta con este correo", `email-already-in-use` → "Este correo ya está registrado", `weak-password` → "La contraseña debe tener al menos 6 caracteres". |
| `FirestoreService` | `FirebaseException` | Loguear error, mostrar `SnackBar` genérico: "Error de conexión. Intenta de nuevo." |
| `LLMService` | `SocketException` / `TimeoutException` | Activar estado Retry en el provider. Timeout DEBE ser de 30 segundos. |
| `LLMService` | `LLMApiException` | Loguear statusCode, activar estado Retry. |
| `LLMService` | `LLMJsonParseException` | Loguear respuesta cruda (truncada a 500 chars), activar estado Retry. |
| `LLMService` | `LLMValidationException` | Loguear razón, activar estado Retry. |
| `WeeklyPlanProvider` | Cualquier excepción no capturada | Catch genérico, activar estado Retry, loguear en consola. |

### 6.4 Seguridad de API Keys

- Las API Keys NUNCA DEBEN estar hardcodeadas en el código fuente.
- El archivo `.env` DEBE estar listado en `.gitignore`.
- Se DEBE crear un archivo `.env.example` con las claves sin valores:

```
LLM_PROVIDER=
LLM_API_KEY=
LLM_MODEL=
LLM_API_URL=
```

- En `main.dart`, se DEBE cargar el archivo `.env` antes de `runApp()`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  runApp(const FitCoachApp());
}
```

- La clase `LLMService` DEBE leer las credenciales exclusivamente desde `dotenv.env['LLM_API_KEY']`.

### 6.5 Reglas de Seguridad Adicionales

- El archivo `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) DEBEN estar en `.gitignore`.
- Toda comunicación con APIs externas DEBE ser sobre HTTPS.
- Los datos del usuario en Firestore solo son accesibles por el propietario (ver reglas en Sección 3.3).

---

## 7. Pruebas Unitarias

### 7.1 Obligatoriedad

El proyecto DEBE incluir al menos los siguientes archivos de prueba dentro del directorio `test/`:

```
test/
├── models/
│   ├── weekly_plan_test.dart
│   └── user_profile_test.dart
└── services/
    └── prompt_builder_test.dart
```

### 7.2 Test: Parseo de `WeeklyPlan` desde JSON Mockeado

**Archivo:** `test/models/weekly_plan_test.dart`

Este test es OBLIGATORIO y valida que los modelos de datos pueden parsear correctamente un JSON con la estructura esperada del LLM.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitcoach_ai/models/weekly_plan.dart';

void main() {
  group('WeeklyPlan.fromJson', () {
    
    final mockLLMResponse = {
      "diet": {
        "daily_calories": 2500,
        "macros": {
          "protein_g": 180,
          "carbs_g": 280,
          "fat_g": 75
        },
        "meals": [
          {
            "name": "Desayuno",
            "description": "Avena con plátano, miel y nueces",
            "calories": 500
          },
          {
            "name": "Media Mañana",
            "description": "Yogur griego con frutos rojos",
            "calories": 300
          },
          {
            "name": "Almuerzo",
            "description": "Pechuga de pollo con arroz integral y brócoli",
            "calories": 700
          },
          {
            "name": "Merienda",
            "description": "Batido de proteína con avena",
            "calories": 400
          },
          {
            "name": "Cena",
            "description": "Salmón al horno con ensalada mixta",
            "calories": 600
          }
        ]
      },
      "training_days": [
        {
          "day_index": 1,
          "day_label": "Lunes",
          "muscle_group": "Pecho y Tríceps",
          "exercises": [
            {
              "exercise_id": "ex_001",
              "name": "Press de banca",
              "sets": 4,
              "reps": "8-12",
              "rest_seconds": 90,
              "completed": false
            },
            {
              "exercise_id": "ex_002",
              "name": "Aperturas con mancuernas",
              "sets": 3,
              "reps": "12-15",
              "rest_seconds": 60,
              "completed": false
            }
          ]
        }
      ]
    };

    test('DEBE parsear correctamente un JSON válido del LLM', () {
      final plan = WeeklyPlan.fromJson({
        'plan_id': 'test_uid_2026-W19',
        'uid': 'test_uid',
        'generated_at': DateTime.now().toIso8601String(),
        'week_label': '2026-W19',
        ...mockLLMResponse,
      });

      // Validaciones de dieta
      expect(plan.diet.dailyCalories, equals(2500));
      expect(plan.diet.macros.proteinG, equals(180));
      expect(plan.diet.macros.carbsG, equals(280));
      expect(plan.diet.macros.fatG, equals(75));
      expect(plan.diet.meals.length, equals(5));
      expect(plan.diet.meals[0].name, equals('Desayuno'));

      // Validaciones de entrenamiento
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
          expect(exercise.completed, isFalse,
              reason: 'Ejercicio "${exercise.name}" no debería estar completado');
        }
      }
    });

    test('DEBE lanzar excepción con JSON incompleto (sin campo diet)', () {
      expect(
        () => WeeklyPlan.fromJson({
          'plan_id': 'test_uid_2026-W19',
          'uid': 'test_uid',
          'generated_at': DateTime.now().toIso8601String(),
          'week_label': '2026-W19',
          'training_days': [],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('DEBE lanzar excepción con JSON incompleto (sin campo training_days)', () {
      expect(
        () => WeeklyPlan.fromJson({
          'plan_id': 'test_uid_2026-W19',
          'uid': 'test_uid',
          'generated_at': DateTime.now().toIso8601String(),
          'week_label': '2026-W19',
          'diet': mockLLMResponse['diet'],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
```

### 7.3 Test: Parseo de `UserProfile` desde JSON

**Archivo:** `test/models/user_profile_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitcoach_ai/models/user_profile.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('DEBE parsear correctamente un perfil completo', () {
      final json = {
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
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.uid, equals('abc123'));
      expect(profile.age, equals(25));
      expect(profile.weightKg, equals(80.0));
      expect(profile.allergies, contains('Maní'));
      expect(profile.injuries.length, equals(1));
      expect(profile.onboardingCompleted, isTrue);
    });

    test('DEBE manejar listas vacías de alergias y lesiones', () {
      final json = {
        'uid': 'abc123',
        'email': 'test@example.com',
        'age': 30,
        'gender': 'femenino',
        'weight_kg': 60.0,
        'height_cm': 165.0,
        'goal': 'definicion',
        'training_days_per_week': 4,
        'allergies': [],
        'injuries': [],
        'onboarding_completed': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.allergies, isEmpty);
      expect(profile.injuries, isEmpty);
    });
  });

  group('UserProfile.toJson', () {
    test('DEBE generar un mapa serializable a Firestore', () {
      final json = {
        'uid': 'abc123',
        'email': 'test@example.com',
        'age': 25,
        'gender': 'masculino',
        'weight_kg': 80.0,
        'height_cm': 175.0,
        'goal': 'volumen',
        'training_days_per_week': 5,
        'allergies': ['Maní'],
        'injuries': [],
        'onboarding_completed': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final profile = UserProfile.fromJson(json);
      final output = profile.toJson();

      expect(output['uid'], equals('abc123'));
      expect(output['weight_kg'], equals(80.0));
      expect(output['allergies'], isA<List>());
    });
  });
}
```

### 7.4 Test: Construcción del Prompt

**Archivo:** `test/services/prompt_builder_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitcoach_ai/utils/prompt_builder.dart';
import 'package:fitcoach_ai/models/user_profile.dart';

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

    test('DEBE mostrar "Ninguna" cuando alergias y lesiones están vacías', () {
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
```

---

## Apéndice A: Checklist de Implementación

El desarrollador o asistente de código DEBE verificar cada ítem antes de considerar el MVP como completo:

- [ ] `pubspec.yaml` contiene todas las dependencias listadas en §1.4.
- [ ] Estructura de directorios coincide con §2.1.
- [ ] Modelos `UserProfile` y `WeeklyPlan` implementan `fromJson`, `toJson` y `copyWith`.
- [ ] Reglas de Firestore desplegadas según §3.3.
- [ ] `AuthScreen` maneja login y registro con validación y mapeo de errores.
- [ ] `OnboardingScreen` valida todos los campos con los rangos especificados.
- [ ] `DashboardScreen` muestra dieta, macros y botón de rutina.
- [ ] `DailyRoutineScreen` muestra ejercicios del día con checkboxes funcionales.
- [ ] Checkboxes actualizan Firestore en tiempo real.
- [ ] `LLMService` soporta al menos un proveedor (OpenAI o Gemini).
- [ ] Prompt del sistema y del usuario coinciden con §5.2.
- [ ] Retry UI implementada según §6.2 con backoff exponencial.
- [ ] API Keys cargadas desde `.env` vía `flutter_dotenv`.
- [ ] `.env` y archivos de configuración Firebase en `.gitignore`.
- [ ] Los tres archivos de test (§7.2, §7.3, §7.4) pasan con `flutter test`.

---

## Apéndice B: Glosario

| Término | Definición |
|---|---|
| **Semana ISO** | Semana según estándar ISO 8601, formato `YYYY-Www`. Lunes = día 1. |
| **Plan semanal** | Documento en Firestore que contiene la dieta y rutinas generadas por el LLM para una semana específica de un usuario. |
| **Onboarding** | Proceso de recopilación de datos del usuario que ocurre una única vez tras el primer registro. |
| **Retry UI** | Componente visual que se muestra cuando una operación falla, ofreciendo al usuario la posibilidad de reintentar. |
| **Backoff exponencial** | Estrategia de reintento donde el tiempo de espera se duplica en cada intento sucesivo. |
| **MVP** | Producto Mínimo Viable. Versión funcional con el mínimo de características necesarias. |
