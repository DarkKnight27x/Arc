import '../enums.dart';
import 'meal.dart';

class MealPlan {
  const MealPlan({
    required this.id,
    required this.userId,
    required this.name,
    this.status = PlanStatus.draft,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final PlanStatus status;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MealPlan.fromMap(Map<String, dynamic> row) {
    return MealPlan(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      status: _status(row['status'] as String?),
      version: (row['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

class MealPlanItem {
  const MealPlanItem({
    required this.id,
    required this.mealPlanId,
    required this.weekday,
    required this.mealType,
    required this.mealId,
    this.servings = 1,
    this.notes,
    this.meal,
  });

  final String id;
  final String mealPlanId;
  final int weekday;
  final MealType mealType;
  final String mealId;
  final double servings;
  final String? notes;
  final Meal? meal;

  factory MealPlanItem.fromMap(Map<String, dynamic> row) {
    Meal? nested;
    final rawMeal = row['meals'];
    if (rawMeal is Map<String, dynamic>) {
      nested = Meal.fromMap(rawMeal);
    }
    return MealPlanItem(
      id: row['id'] as String,
      mealPlanId: row['meal_plan_id'] as String,
      weekday: (row['weekday'] as num?)?.toInt() ?? 1,
      mealType: mealTypeFromDb(row['meal_type'] as String?),
      mealId: row['meal_id'] as String,
      servings: _num(row['servings'], fallback: 1),
      notes: row['notes'] as String?,
      meal: nested,
    );
  }
}

PlanStatus _status(String? raw) {
  switch (raw) {
    case 'active':
      return PlanStatus.active;
    case 'paused':
      return PlanStatus.paused;
    case 'archived':
      return PlanStatus.archived;
    default:
      return PlanStatus.draft;
  }
}

double _num(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}