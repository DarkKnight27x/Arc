import '../enums.dart';
import 'meal.dart';

class MealNutrition {
  const MealNutrition({
    required this.mealId,
    required this.name,
    required this.mealType,
    this.imagePath,
    this.dietaryTags = const [],
    this.cuisine,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String mealId;
  final String name;
  final MealType mealType;
  final String? imagePath;
  final List<String> dietaryTags;
  final String? cuisine;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  factory MealNutrition.fromMap(Map<String, dynamic> row) {
    return MealNutrition(
      mealId: row['meal_id'] as String,
      name: row['name'] as String,
      mealType: mealTypeFromDb(row['meal_type'] as String?),
      imagePath: row['image_path'] as String?,
      dietaryTags: row['dietary_tags'] is List
          ? (row['dietary_tags'] as List).map((e) => e.toString()).toList()
          : const [],
      cuisine: row['cuisine'] as String?,
      caloriesKcal: _num(row['calories_kcal']),
      proteinG: _num(row['protein_g']),
      carbsG: _num(row['carbs_g']),
      fatG: _num(row['fat_g']),
    );
  }
}

double _num(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}