import 'package:supabase_flutter/supabase_flutter.dart';

import 'enums.dart';
import 'models/food.dart';
import 'models/meal.dart';
import 'models/meal_ingredient.dart';
import 'models/meal_nutrition.dart';
import 'models/meal_plan.dart';
import 'storage_service.dart';

class MealDetail {
  const MealDetail({
    required this.meal,
    required this.ingredients,
    this.nutrition,
  });

  final Meal meal;
  final List<MealIngredient> ingredients;
  final MealNutrition? nutrition;

  double get caloriesKcal =>
      nutrition?.caloriesKcal ??
          ingredients.fold(0, (sum, line) => sum + line.caloriesKcal);

  double get proteinG =>
      nutrition?.proteinG ??
          ingredients.fold(0, (sum, line) => sum + line.proteinG);
}

class MealService {
  MealService(this._client) : storage = StorageService(_client);

  final SupabaseClient _client;
  final StorageService storage;

  Future<List<MealNutrition>> listCatalog({
    MealType? mealType,
    List<String> dietaryTags = const [],
  }) async {
    var query = _client.from('meal_nutrition').select();
    if (mealType != null) {
      query = query.eq('meal_type', mealTypeToDb(mealType));
    }
    if (dietaryTags.isNotEmpty) {
      query = query.overlaps('dietary_tags', dietaryTags);
    }
    final rows = await query.order('name');
    return (rows as List)
        .map((row) => MealNutrition.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<Meal>> listPublishedMeals({MealType? mealType}) async {
    var query = _client.from('meals').select().eq('is_published', true);
    if (mealType != null) {
      query = query.eq('meal_type', mealTypeToDb(mealType));
    }
    final rows = await query.order('name');
    return (rows as List)
        .map((row) => Meal.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<MealDetail?> fetchDetail(String mealId) async {
    final mealRow = await _client
        .from('meals')
        .select()
        .eq('id', mealId)
        .maybeSingle();
    if (mealRow == null) return null;

    final ingredientRows = await _client
        .from('meal_ingredients')
        .select('*, foods(*)')
        .eq('meal_id', mealId)
        .order('sort_order');

    final nutritionRow = await _client
        .from('meal_nutrition')
        .select()
        .eq('meal_id', mealId)
        .maybeSingle();

    return MealDetail(
      meal: Meal.fromMap(Map<String, dynamic>.from(mealRow)),
      ingredients: (ingredientRows as List)
          .map(
            (row) => MealIngredient.fromMap(Map<String, dynamic>.from(row as Map)),
      )
          .toList(),
      nutrition: nutritionRow == null
          ? null
          : MealNutrition.fromMap(Map<String, dynamic>.from(nutritionRow)),
    );
  }

  String? imageUrl(String? path) => storage.mealImageUrl(path);
}