import 'food.dart';

class MealIngredient {
  const MealIngredient({
    required this.id,
    required this.mealId,
    required this.foodId,
    required this.quantity,
    required this.unit,
    required this.sortOrder,
    this.food,
  });

  final String id;
  final String mealId;
  final String foodId;
  final double quantity;
  final String unit;
  final int sortOrder;
  final Food? food;

  factory MealIngredient.fromMap(Map<String, dynamic> row) {
    Food? nested;
    final rawFood = row['foods'];
    if (rawFood is Map<String, dynamic>) {
      nested = Food.fromMap(rawFood);
    }
    return MealIngredient(
      id: row['id'] as String,
      mealId: row['meal_id'] as String,
      foodId: row['food_id'] as String,
      quantity: _num(row['quantity']),
      unit: row['unit'] as String? ?? 'g',
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      food: nested,
    );
  }

  double get caloriesKcal {
    final f = food;
    if (f == null) return 0;
    return f.scale(f.caloriesKcal, quantity);
  }

  double get proteinG {
    final f = food;
    if (f == null) return 0;
    return f.scale(f.proteinG, quantity);
  }
}

double _num(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}