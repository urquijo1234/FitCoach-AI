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

  const UserProfile({
    required this.uid,
    required this.email,
    required this.age,
    required this.gender,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.trainingDaysPerWeek,
    required this.allergies,
    required this.injuries,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      heightCm: (json['height_cm'] as num).toDouble(),
      goal: json['goal'] as String,
      trainingDaysPerWeek: json['training_days_per_week'] as int,
      allergies: List<String>.from(json['allergies'] as List<dynamic>),
      injuries: List<String>.from(json['injuries'] as List<dynamic>),
      onboardingCompleted: json['onboarding_completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'age': age,
      'gender': gender,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'goal': goal,
      'training_days_per_week': trainingDaysPerWeek,
      'allergies': allergies,
      'injuries': injuries,
      'onboarding_completed': onboardingCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    int? age,
    String? gender,
    double? weightKg,
    double? heightCm,
    String? goal,
    int? trainingDaysPerWeek,
    List<String>? allergies,
    List<String>? injuries,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      goal: goal ?? this.goal,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      allergies: allergies ?? this.allergies,
      injuries: injuries ?? this.injuries,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
