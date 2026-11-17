/// What a customer told Gud Meal about how they eat (the "Food preferences" part of the profile).
class FoodPreferences {
  const FoodPreferences({this.allergens = const [], this.dietary = const [], this.personalise = false});

  /// Things the customer must not eat; Gudy never recommends dishes that list them.
  final List<String> allergens;

  /// "vegetarian", "halal" ...
  final List<String> dietary;

  /// The customer agreed that their orders and preferences may shape recommendations.
  final bool personalise;

  static List<String> _words(Object? value) => [for (final v in (value as List? ?? const [])) '$v'];

  /// "Peanuts, shellfish ,  " becomes ["peanuts", "shellfish"].
  static List<String> split(String text) =>
      [for (final part in text.split(',')) if (part.trim().isNotEmpty) part.trim().toLowerCase()];

  factory FoodPreferences.fromJson(Map<String, dynamic> json) => FoodPreferences(
        allergens: _words(json['allergens']),
        dietary: _words(json['dietary']),
        personalise: json['personalisation_consent'] == true,
      );

  Map<String, dynamic> toJson() => {'allergens': allergens, 'dietary': dietary, 'personalisation_consent': personalise};
}
