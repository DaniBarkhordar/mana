/// The one rule for turning a scale reading into a stored body measurement.
///
/// Used by the live recorder (a settled sample as someone stands on the
/// scale) and by the stored-readings catch-up (what the scale remembered
/// while the phone was away). Both must decide consent the same way, on the
/// same inputs, or a reading taken on Tuesday and synced on Thursday could be
/// treated differently from one taken with the phone in hand.
library;

import '../bia/body_composition.dart';
import '../bia/equations.dart';
import 'models.dart';
import 'repositories/body_repository.dart';
import 'repositories/profile_repository.dart';

/// Stores one reading, or returns null when there is no profile to store it
/// against (every equation needs height, age and sex).
///
/// Composition is only computed with consent: without it the impedance is
/// dropped before the engine sees it, and the reading is stored weight-only.
/// Consent is read from the database, not from a provider nobody may be
/// watching, because the answer has to be the standing decision at this
/// instant.
Future<String?> recordBodyReading({
  required ProfileRepository profiles,
  required BodyRepository body,
  required double kg,
  required DateTime at,
  required String source,
  required String driverName,
  double? impedanceOhm,
  double? reactanceOhm,
}) async {
  final profile = await profiles.currentProfile();
  if (profile == null) return null;
  final consent = await profiles.latestConsent(ConsentRecord.bodyComposition);
  final consented = consent?.granted ?? false;

  final input = BiaInput(
    heightCm: profile.heightCm,
    weightKg: kg,
    ageYears: profile.ageOn(at),
    sex: profile.sex,
    resistanceOhm: consented ? impedanceOhm : null,
    reactanceOhm: consented ? reactanceOhm : null,
  );
  final result = const BodyCompositionEngine().evaluate(
    input: input,
    takenAt: at,
  );
  return body.record(
    result: result,
    input: input,
    source: source,
    raw: {
      'kg': kg,
      'impedance_ohm': impedanceOhm,
      'reactance_ohm': reactanceOhm,
      'driver': driverName,
    },
  );
}
