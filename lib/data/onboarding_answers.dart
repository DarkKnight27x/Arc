import 'profile_validation.dart';

class OnboardingAnswers {
  String? goal;
  String? sex;
  String? age;
  String? heightCm;
  String? weightKg;
  String? level;
  String? days;
  String? diet;
  List<String> allergies = [];

  static bool validNumber(String? text, String field) =>
      text != null &&
      text.trim().isNotEmpty &&
      ProfileValidation.numeric(text, field) == null;

  Map<String, dynamic> completionPatch() {
    if (!ProfileValidation.goals.contains(goal) ||
        !['Male', 'Female'].contains(sex) ||
        !ProfileValidation.levels.contains(level) ||
        !['3', '4', '5', '6'].contains(days) ||
        !ProfileValidation.diets.contains(diet) ||
        !validNumber(age, 'age') ||
        int.tryParse(age!.trim()) == null ||
        !validNumber(heightCm, 'height_cm') ||
        !validNumber(weightKg, 'weight_kg') ||
        allergies.isEmpty ||
        allergies.any((v) => !ProfileValidation.allergies.contains(v)) ||
        allergies.toSet().length != allergies.length ||
        (allergies.contains('None') && allergies.length != 1)) {
      throw const FormatException(
        'Complete every step with valid information.',
      );
    }
    return {
      'fitness_goal': goal,
      'gender': sex,
      'age': int.parse(age!.trim()),
      'height_cm': double.parse(heightCm!.trim()),
      'weight_kg': double.parse(weightKg!.trim()),
      'experience_level': level,
      'train_days': int.parse(days!),
      'diet_type': diet,
      'allergies': List<String>.of(allergies),
      'onboarding_complete': true,
    };
  }
}
