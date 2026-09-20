class Food {
  const Food({
    required this.id,
    required this.name,
    required this.servingAmount,
    required this.servingUnit,
    required this.caloriesKcal,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fibreG,
    this.dietaryTags = const [],
    this.allergenTags = const [],
    this.isPublished = true,
    this.source,
    this.sourceCode,
    this.imagePath,
  });

  final String id;
  final String name;
  final double servingAmount;
  final String servingUnit;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fibreG;
  final List<String> dietaryTags;
  final List<String> allergenTags;
  final bool isPublished;
  final String? source;
  final String? sourceCode;
  final String? imagePath;

  factory Food.fromMap(Map<String, dynamic> row) {
    return Food(
      id: row['id'] as String,
      name: row['name'] as String,
      servingAmount: _num(row['serving_amount']),
      servingUnit: row['serving_unit'] as String,
      caloriesKcal: _num(row['calories_kcal']),
      proteinG: _num(row['protein_g']),
      carbsG: _num(row['carbs_g']),
      fatG: _num(row['fat_g']),
      fibreG: row['fibre_g'] == null ? null : _num(row['fibre_g']),
      dietaryTags: _strings(row['dietary_tags']),
      allergenTags: _strings(row['allergen_tags']),
      isPublished: row['is_published'] as bool? ?? true,
      source: row['source'] as String?,
      sourceCode: row['source_code'] as String?,
      imagePath: row['image_path'] as String?,
    );
  }

  double scale(double perServing, double grams) =>
      servingAmount == 0 ? 0 : perServing * (grams / servingAmount);
}

double _num(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

List<String> _strings(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}