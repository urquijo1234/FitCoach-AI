class WeeklyPlan {
  final String planId;
  final String uid;
  final DateTime generatedAt;
  final String weekLabel;
  final Diet diet;
  final List<TrainingDay> trainingDays;

  const WeeklyPlan({
    required this.planId,
    required this.uid,
    required this.generatedAt,
    required this.weekLabel,
    required this.diet,
    required this.trainingDays,
  });

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    if (json['diet'] == null || json['training_days'] == null) {
      throw const FormatException('Missing required fields: diet/training_days');
    }

    return WeeklyPlan(
      planId: json['plan_id'] as String,
      uid: json['uid'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      weekLabel: json['week_label'] as String,
      diet: Diet.fromJson(json['diet'] as Map<String, dynamic>),
      trainingDays: (json['training_days'] as List<dynamic>)
          .map((day) => TrainingDay.fromJson(day as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'uid': uid,
        'generated_at': generatedAt.toIso8601String(),
        'week_label': weekLabel,
        'diet': diet.toJson(),
        'training_days': trainingDays.map((day) => day.toJson()).toList(),
      };

  WeeklyPlan copyWith({
    String? planId,
    String? uid,
    DateTime? generatedAt,
    String? weekLabel,
    Diet? diet,
    List<TrainingDay>? trainingDays,
  }) {
    return WeeklyPlan(
      planId: planId ?? this.planId,
      uid: uid ?? this.uid,
      generatedAt: generatedAt ?? this.generatedAt,
      weekLabel: weekLabel ?? this.weekLabel,
      diet: diet ?? this.diet,
      trainingDays: trainingDays ?? this.trainingDays,
    );
  }
}

class Diet {
  final int dailyCalories;
  final Macros macros;
  final List<Meal> meals;

  const Diet({
    required this.dailyCalories,
    required this.macros,
    required this.meals,
  });

  factory Diet.fromJson(Map<String, dynamic> json) => Diet(
        dailyCalories: json['daily_calories'] as int,
        macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
        meals: (json['meals'] as List<dynamic>)
            .map((meal) => Meal.fromJson(meal as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'daily_calories': dailyCalories,
        'macros': macros.toJson(),
        'meals': meals.map((meal) => meal.toJson()).toList(),
      };
}

class Macros {
  final int proteinG;
  final int carbsG;
  final int fatG;

  const Macros({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory Macros.fromJson(Map<String, dynamic> json) => Macros(
        proteinG: json['protein_g'] as int,
        carbsG: json['carbs_g'] as int,
        fatG: json['fat_g'] as int,
      );

  Map<String, dynamic> toJson() => {
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
      };
}

class Meal {
  final String name;
  final String description;
  final int calories;

  const Meal({
    required this.name,
    required this.description,
    required this.calories,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        name: json['name'] as String,
        description: json['description'] as String,
        calories: json['calories'] as int,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'calories': calories,
      };
}

class TrainingDay {
  final int dayIndex;
  final String dayLabel;
  final String muscleGroup;
  final List<Exercise> exercises;

  const TrainingDay({
    required this.dayIndex,
    required this.dayLabel,
    required this.muscleGroup,
    required this.exercises,
  });

  factory TrainingDay.fromJson(Map<String, dynamic> json) => TrainingDay(
        dayIndex: json['day_index'] as int,
        dayLabel: json['day_label'] as String,
        muscleGroup: json['muscle_group'] as String,
        exercises: (json['exercises'] as List<dynamic>)
            .map((exercise) =>
                Exercise.fromJson(exercise as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'day_index': dayIndex,
        'day_label': dayLabel,
        'muscle_group': muscleGroup,
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      };
}

class Exercise {
  final String exerciseId;
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  bool completed;

  Exercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.completed,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        exerciseId: json['exercise_id'] as String,
        name: json['name'] as String,
        sets: json['sets'] as int,
        reps: json['reps'] as String,
        restSeconds: json['rest_seconds'] as int,
        completed: json['completed'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'name': name,
        'sets': sets,
        'reps': reps,
        'rest_seconds': restSeconds,
        'completed': completed,
      };
}
