import 'package:flutter/material.dart';

import '../../data/meal_service.dart';

class MealDetailPage extends StatelessWidget {
  const MealDetailPage({
    super.key,
    required this.detail,
    required this.imageUrl,
  });

  final MealDetail detail;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final meal = detail.meal;
    return Scaffold(
      appBar: AppBar(title: Text(meal.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl!, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          Text(
            '${detail.caloriesKcal.round()} kcal  ·  ${detail.proteinG.toStringAsFixed(0)} g protein',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (meal.description != null) ...[
            const SizedBox(height: 8),
            Text(meal.description!),
          ],
          const SizedBox(height: 20),
          Text('Ingredients', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...detail.ingredients.map(
                (line) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(line.food?.name ?? line.foodId),
              trailing: Text('${line.quantity.toStringAsFixed(0)} ${line.unit}'),
            ),
          ),
          if (meal.recipeSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Steps', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...meal.recipeSteps.asMap().entries.map(
                  (e) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text('${e.key + 1}'),
                title: Text(e.value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}