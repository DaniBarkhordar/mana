/// Domain objects that live between the screens and the database, and the
/// small codecs that map enums onto the Postgres labels.
library;

import '../bia/equations.dart';
import '../nutrition/models.dart';
import '../nutrition/portion.dart';

/// The user's measurement profile.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.heightCm,
    required this.dateOfBirth,
    required this.sex,
    this.activity = ActivityLevel.lowActive,
    this.displayName,
  });

  final String id;
  final double heightCm;

  /// Kept as a date so the age advances on its own. Every measurement stores
  /// the age it was taken at, so the past does not move.
  final DateTime dateOfBirth;
  final Sex sex;
  final ActivityLevel activity;
  final String? displayName;

  int ageOn(DateTime day) {
    var age = day.year - dateOfBirth.year;
    final hadBirthday = day.month > dateOfBirth.month ||
        (day.month == dateOfBirth.month && day.day >= dateOfBirth.day);
    if (!hadBirthday) age--;
    return age;
  }

  int get ageYears => ageOn(DateTime.now());

  /// A date of birth from an age given in onboarding. Mid-year, so the age is
  /// right for half a year either way; the user can correct it in Settings.
  static DateTime dateOfBirthForAge(int ageYears, {DateTime? today}) {
    final now = today ?? DateTime.now();
    return DateTime(now.year - ageYears, 7, 1);
  }

  UserProfile copyWith({
    double? heightCm,
    DateTime? dateOfBirth,
    Sex? sex,
    ActivityLevel? activity,
    String? displayName,
  }) =>
      UserProfile(
        id: id,
        heightCm: heightCm ?? this.heightCm,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        sex: sex ?? this.sex,
        activity: activity ?? this.activity,
        displayName: displayName ?? this.displayName,
      );
}

/// A meal as logged, with its components.
class LoggedMeal {
  const LoggedMeal({
    required this.id,
    required this.eatenAt,
    required this.slot,
    required this.components,
    this.isSynced = false,
  });

  final String id;
  final DateTime eatenAt;
  final MealSlot slot;
  final List<LoggedComponent> components;

  /// False until the row has reached the server. Shown, quietly, so the user
  /// knows a meal logged on the train is safe on the phone but not yet backed
  /// up.
  final bool isSynced;

  MealTotals get totals => MealTotals.from(components);
}

enum MealSlot {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snack');

  const MealSlot(this.label);

  final String label;

  static MealSlot forHour(int hour) {
    if (hour < 11) return MealSlot.breakfast;
    if (hour < 15) return MealSlot.lunch;
    if (hour < 21) return MealSlot.dinner;
    return MealSlot.snack;
  }

  static MealSlot parse(String s) =>
      MealSlot.values.firstWhere((v) => v.name == s, orElse: () => snack);
}

/// A consent grant or withdrawal, as recorded.
class ConsentRecord {
  const ConsentRecord({
    required this.purpose,
    required this.policyVersion,
    required this.granted,
    required this.grantedAt,
  });

  static const bodyComposition = 'body_composition';
  static const photoRecognition = 'photo_recognition';

  /// Bump when the wording the user agreed to changes.
  static const currentPolicyVersion = '2026-09-06';

  final String purpose;
  final String policyVersion;
  final bool granted;
  final DateTime grantedAt;
}

// ---------------------------------------------------------------------------
// Enum codecs. Dart names are camelCase; the Postgres enums are snake_case.
// ---------------------------------------------------------------------------

String encodeSex(Sex s) => s.name;

Sex? decodeSex(String? s) => switch (s) {
      'male' => Sex.male,
      'female' => Sex.female,
      _ => null,
    };

String encodeActivity(ActivityLevel a) => switch (a) {
      ActivityLevel.inactive => 'inactive',
      ActivityLevel.lowActive => 'low_active',
      ActivityLevel.active => 'active',
      ActivityLevel.veryActive => 'very_active',
    };

ActivityLevel decodeActivity(String? s) => switch (s) {
      'inactive' => ActivityLevel.inactive,
      'active' => ActivityLevel.active,
      'very_active' => ActivityLevel.veryActive,
      _ => ActivityLevel.lowActive,
    };

String encodePortionMethod(PortionMethod m) => switch (m) {
      PortionMethod.weighed => 'weighed',
      PortionMethod.householdMeasure => 'household_measure',
      PortionMethod.photoEstimate => 'photo_estimate',
      PortionMethod.manualGrams => 'manual_grams',
    };

PortionMethod decodePortionMethod(String s) => switch (s) {
      'household_measure' => PortionMethod.householdMeasure,
      'photo_estimate' => PortionMethod.photoEstimate,
      'manual_grams' => PortionMethod.manualGrams,
      _ => PortionMethod.weighed,
    };

String encodeNutritionSource(NutritionSource s) => switch (s) {
      NutritionSource.cofid => 'cofid',
      NutritionSource.usda => 'usda',
      NutritionSource.openFoodFacts => 'open_food_facts',
      NutritionSource.userLabel => 'user_label',
      NutritionSource.userRecipe => 'user_recipe',
      NutritionSource.estimated => 'estimated',
    };

NutritionSource decodeNutritionSource(String? s) => switch (s) {
      'cofid' => NutritionSource.cofid,
      'usda' => NutritionSource.usda,
      'open_food_facts' => NutritionSource.openFoodFacts,
      'user_label' => NutritionSource.userLabel,
      'user_recipe' => NutritionSource.userRecipe,
      _ => NutritionSource.estimated,
    };

/// `YYYY-MM-DD` for Postgres `date` columns.
String encodeDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? decodeDate(String? s) => s == null ? null : DateTime.tryParse(s);
