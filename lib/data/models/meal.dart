import '../enums.dart';

class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.mealType,
    this.description,
    this.recipeSteps = const [],
    this.imagePath,
    this.dietaryTags = const [],
    this.isPublished = true,
    this.source,
    this.sourceCode,
    this.cuisine,
    this.defaultServings = 1,
    this.yieldGrams,
  });

  final String id;
  final String name;
  final MealType mealType;
  final String? description;
  final List<String> recipeSteps;
  final String? imagePath;
  final List<String> dietaryTags;
  final bool isPublished;
  final String? source;
  final String? sourceCode;
  final String? cuisine;
  final double defaultServings;
  final double? yieldGrams;

  factory Meal.fromMap(Map<String, dynamic> row) {
    return Meal(
      id: row['id'] as String,
      name: row['name'] as String,
      mealType: mealTypeFromDb(row['meal_type'] as String?),
      description: row['description'] as String?,
      recipeSteps: _strings(row['recipe_steps']),
      imagePath: row['image_path'] as String?,
      dietaryTags: _strings(row['dietary_tags']),
      isPublished: row['is_published'] as bool? ?? true,
      source: row['source'] as String?,
      sourceCode: row['source_code'] as String?,
      cuisine: row['cuisine'] as String?,
      defaultServings: _num(row['default_servings'], fallback: 1),
      yieldGrams: row['yield_grams'] == null ? null : _num(row['yield_grams']),
    );
  }
}

MealType mealTypeFromDb(String? raw) {
  switch (raw) {
    case 'breakfast':
      return MealType.breakfast;
    case 'lunch':
      return MealType.lunch;
    case 'dinner':
      return MealType.dinner;
    case 'snack':
      return MealType.snack;
    default:
      return MealType.lunch;
  }
}

String mealTypeToDb(MealType type) {
  switch (type) {
    case MealType.breakfast:
      return 'breakfast';
    case MealType.lunch:
      return 'lunch';
    case MealType.dinner:
      return 'dinner';
    case MealType.snack:
      return 'snack';
  }
}

double _num(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

List<String> _strings(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}