/// The edit surface shares onboarding's stored values. No database-only fields
/// (identity, onboarding, state, timestamps, etc.) may pass through this patch.
class ProfileValidation {
  static const goals = ['Build muscle', 'Lose fat', 'Stay consistent'];
  static const levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const locations = ['Gym', 'Home', 'Both', 'Outdoors'];
  static const diets = ['Veg', 'Nonveg', 'Vegan', 'Eggetarian'];
  static const allergies = ['Dairy', 'Gluten', 'Nuts', 'Eggs', 'None'];
  static const fields = {
    'display_name',
    'fitness_goal',
    'experience_level',
    'train_days',
    'workout_location',
    'height_cm',
    'weight_kg',
    'diet_type',
    'allergies',
    'age',
  };

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your name.';
    if (text.length > 80) return 'Use 80 characters or fewer.';
    return null;
  }

  static String? numeric(String? value, String field) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    final (min, max, label) = switch (field) {
      'height_cm' => (80, 250, 'height between 80 and 250 cm'),
      'weight_kg' => (20, 350, 'weight between 20 and 350 kg'),
      'age' => (13, 120, 'age between 13 and 120'),
      'train_days' => (1, 7, '1 to 7 training days'),
      _ => throw ArgumentError('Unknown numeric field'),
    };
    if (number == null || !number.isFinite || number < min || number > max) {
      return 'Enter $label.';
    }
    if ((field == 'age' || field == 'train_days') &&
        number != number.roundToDouble()) {
      return 'Enter a whole number.';
    }
    return null;
  }

  static Map<String, dynamic> changedFields(
    Map<String, dynamic> original,
    Map<String, dynamic> edited,
  ) {
    final patch = <String, dynamic>{};
    for (final key in fields) {
      if (!edited.containsKey(key)) continue;
      final before = original[key];
      final after = edited[key];
      final equal = before is List && after is List
          ? before.length == after.length && before.every(after.contains)
          : before == after;
      if (!equal) patch[key] = after;
    }
    return patch;
  }

  static void validatePatch(Map<String, dynamic> patch) {
    if (patch.keys.any((key) => !fields.contains(key))) {
      throw ArgumentError('This field cannot be edited here.');
    }
    for (final entry in patch.entries) {
      final value = entry.value;
      String? error;
      if (entry.key == 'display_name') {
        if (value is! String) throw ArgumentError('Enter your name.');
        error = name(value);
      } else if ([
        'height_cm',
        'weight_kg',
        'age',
        'train_days',
      ].contains(entry.key)) {
        if (value != null && value is! num) {
          throw ArgumentError('Enter a number.');
        }
        error = numeric(value?.toString(), entry.key);
      } else if (entry.key == 'diet_type') {
        if (value != null && !diets.contains(value)) {
          error = 'Choose a supported diet preference.';
        }
      } else if (entry.key == 'allergies') {
        if (value is! List<String> ||
            value.any((item) => item.trim().isEmpty || item.length > 80) ||
            (value.contains('None') && value.length > 1)) {
          error = 'Choose allergies or None, not both.';
        }
      } else if (value != null && (value is! String || value.length > 80)) {
        error = 'Use 80 characters or fewer.';
      }
      if (error != null) throw ArgumentError(error);
    }
  }
}
