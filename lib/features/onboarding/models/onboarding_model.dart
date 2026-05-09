class OnboardingModel {
  final String userId;
  final String? gender;
  final int? age; 
  final double? weight;
  final double? height;
  final String unitSystem;
  final String? objective;

  OnboardingModel({
    required this.userId,
    this.gender,
    this.age,
    this.weight,
    this.height,
    this.unitSystem = 'metric', 
    this.objective,
  });

  OnboardingModel copyWith({
    String? gender,
    int? age,
    double? weight,
    double? height,
    String? unitSystem,
    String? objective,
  }) {
    return OnboardingModel(
      userId: userId,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      unitSystem: unitSystem ?? this.unitSystem,
      objective: objective ?? this.objective,
    );
  }
}