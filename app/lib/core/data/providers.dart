/// Riverpod wiring.
///
/// Kept in one place so the dependency graph is legible: which driver is live,
/// where the live weight comes from, what is read from the local database,
/// and what the app falls back to when there is no hardware and no network.
///
/// Every screen reads from SQLite through a stream. The network only ever
/// fills SQLite in the background (see sync/), so nothing here awaits it.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bia/body_composition.dart';
import '../bia/equations.dart';
import '../nutrition/models.dart';
import '../nutrition/portion.dart';
import '../scale/scale_driver.dart';
import 'db/database.dart';
import 'models.dart';
import 'repositories/body_repository.dart';
import 'repositories/meal_repository.dart';
import 'repositories/observation_repository.dart';
import 'repositories/profile_repository.dart';
import 'sync/supabase_sync_remote.dart';
import 'sync/sync_engine.dart';
import 'sync/sync_scheduler.dart';

export 'models.dart';
export 'sync/sync_engine.dart' show SyncOutcome, SyncReport;

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

/// Supabase project settings, injected at build time:
///
/// ```
/// flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///             --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// ```
///
/// A legacy anon key works in the same slot. Absent, the app runs entirely
/// offline and says so in Settings. Never a service-role key: the client only
/// ever holds the key that row-level security is designed to be shown.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}

/// The database and the repositories over it, opened once at startup.
class AppServices {
  AppServices({
    required this.db,
    required this.profiles,
    required this.meals,
    required this.body,
    required this.observations,
    this.sync,
  });

  /// Everything in memory: tests and previews.
  factory AppServices.inMemory({SyncScheduler? sync}) =>
      AppServices.over(AppDatabase.memory(), sync: sync);

  factory AppServices.over(AppDatabase db, {SyncScheduler? sync}) {
    final observations = ObservationRepository(db);
    return AppServices(
      db: db,
      profiles: ProfileRepository(db),
      meals: MealRepository(db),
      body: BodyRepository(db, observations),
      observations: observations,
      sync: sync,
    );
  }

  final AppDatabase db;
  final ProfileRepository profiles;
  final MealRepository meals;
  final BodyRepository body;
  final ObservationRepository observations;

  /// Null when no backend is configured: the app is local-only.
  final SyncScheduler? sync;

  bool get canSync => sync != null;
}

/// Opens the database and, when configured, the backend. Tolerant on purpose:
/// a cold start with no network must still reach a usable screen, so any
/// failure to reach Supabase leaves the app local-only rather than broken.
final appServicesProvider = FutureProvider<AppServices>((ref) async {
  final db = await AppDatabase.open();
  await db.localUserId();

  SyncScheduler? sync;
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      final engine = SyncEngine(
        db: db,
        remote: SupabaseSyncRemote(Supabase.instance.client),
      );
      sync = SyncScheduler(engine: engine, db: db)..start();
    } on Object {
      sync = null;
    }
  }

  ref.onDispose(() {
    sync?.stop();
    db.close();
  });
  return AppServices.over(db, sync: sync);
});

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  yield* s.profiles.watchProfile();
});

/// The user's standing decision on body-composition processing. Null until
/// onboarding has asked.
final bodyCompositionConsentProvider = StreamProvider<ConsentRecord?>(
  (ref) async* {
    final s = await ref.watch(appServicesProvider.future);
    yield* s.profiles.watchLatestConsent(ConsentRecord.bodyComposition);
  },
);

// ---------------------------------------------------------------------------
// Scales
// ---------------------------------------------------------------------------

/// Which driver is in play.
///
/// [SimulatedScaleDriver] until the vendor driver is wired up (Phase 3).
/// Swapping to [LefuScaleDriver] is a one-line change here and nothing else in
/// the app moves — that is the point of the abstraction. The simulated driver
/// stays in the release build behind a review account (CLAUDE.md rule 9).
final bodyScaleDriverProvider = Provider<ScaleDriver>((ref) {
  final driver = SimulatedScaleDriver(kind: ScaleKind.body);
  ref.onDispose(driver.dispose);
  return driver;
});

final kitchenScaleDriverProvider = Provider<ScaleDriver>((ref) {
  final driver = SimulatedScaleDriver(kind: ScaleKind.kitchen);
  ref.onDispose(driver.dispose);
  return driver;
});

/// Connects both scales at startup. With the simulated driver that finds the
/// demo device; the pairing flow for real hardware arrives with Phase 3.
final scaleSessionProvider = FutureProvider<void>((ref) async {
  for (final driver in [
    ref.watch(bodyScaleDriverProvider),
    ref.watch(kitchenScaleDriverProvider),
  ]) {
    unawaited(_autoConnect(driver));
  }
});

Future<void> _autoConnect(ScaleDriver driver) async {
  try {
    if (!await driver.initialise()) return;
    final found = await driver.scan(timeout: const Duration(seconds: 15)).first;
    await driver.connect(found);
  } on Object {
    // Nothing in range, or Bluetooth off. The readout says so; nothing else
    // depends on it.
  }
}

final kitchenConnectionProvider = StreamProvider<ScaleConnectionState>((ref) {
  return ref.watch(kitchenScaleDriverProvider).connectionState;
});

final bodyConnectionProvider = StreamProvider<ScaleConnectionState>((ref) {
  return ref.watch(bodyScaleDriverProvider).connectionState;
});

/// Live grams from the kitchen scale.
final liveGramsProvider = StreamProvider<WeightSample>((ref) {
  return ref.watch(kitchenScaleDriverProvider).samples;
});

/// Live kg from the body scale.
final liveBodyWeightProvider = StreamProvider<WeightSample>((ref) {
  return ref.watch(bodyScaleDriverProvider).samples;
});

/// Where a reading came from, for the observation row. The simulated driver
/// is labelled as such: a demo reading must never look like a measurement.
String observationSourceFor(ScaleDriver driver, ScaleKind kind) {
  if (driver is SimulatedScaleDriver) return 'simulated_scale';
  return kind == ScaleKind.body ? 'mananu_body_scale' : 'mananu_kitchen_scale';
}

/// Turns each settled body-scale sample into a stored reading. Kept alive by
/// the shell for the app's lifetime.
///
/// Composition is only computed with consent: without it the impedance is
/// dropped before the engine sees it, and the reading is stored weight-only.
final bodyReadingRecorderProvider = Provider<void>((ref) {
  final driver = ref.watch(bodyScaleDriverProvider);
  final sub = driver.samples.listen((sample) async {
    if (!sample.isStable) return;
    final services = ref.read(appServicesProvider).valueOrNull;
    if (services == null) return;
    final profile = await services.profiles.currentProfile();
    if (profile == null) return;
    // Read from the database, not from a provider nobody may be watching:
    // the answer has to be the standing decision at this instant.
    final consent =
        await services.profiles.latestConsent(ConsentRecord.bodyComposition);
    final consented = consent?.granted ?? false;

    final input = BiaInput(
      heightCm: profile.heightCm,
      weightKg: sample.kg,
      ageYears: profile.ageOn(sample.at),
      sex: profile.sex,
      resistanceOhm: consented ? sample.impedanceOhm : null,
      reactanceOhm: consented ? sample.reactanceOhm : null,
    );
    final result = const BodyCompositionEngine().evaluate(
      input: input,
      takenAt: sample.at,
    );
    await services.body.record(
      result: result,
      input: input,
      source: observationSourceFor(driver, ScaleKind.body),
      raw: {
        'kg': sample.kg,
        'impedance_ohm': sample.impedanceOhm,
        'reactance_ohm': sample.reactanceOhm,
        'driver': driver.driverName,
      },
    );
  });
  ref.onDispose(sub.cancel);
});

// ---------------------------------------------------------------------------
// Weighing session (in memory until the meal is logged)
// ---------------------------------------------------------------------------

/// The meal currently being built on the scale.
class WeighSessionNotifier extends StateNotifier<List<LoggedComponent>> {
  WeighSessionNotifier() : super(const []);

  final WeighSession _session = WeighSession();

  double get platformGrams => _session.platformGrams;

  void addFromRunningTotal({
    required FoodItem food,
    required double totalOnScaleGrams,
  }) {
    _session.addFromRunningTotal(
      food: food,
      totalOnScaleGrams: totalOnScaleGrams,
    );
    state = _session.components;
  }

  void addTared({required FoodItem food, required double grams}) {
    _session.addTared(food: food, grams: grams);
    state = _session.components;
  }

  void addUnweighed({
    required FoodItem food,
    required double grams,
    required PortionMethod method,
  }) {
    _session.addUnweighed(food: food, grams: grams, method: method);
    state = _session.components;
  }

  void addCookingFat(CookingFatCapture capture) {
    _session.addCookingFat(capture);
    state = _session.components;
  }

  void removeAt(int i) {
    _session.removeAt(i);
    state = _session.components;
  }

  void reset() {
    _session.reset();
    state = const [];
  }

  MealTotals totals() => _session.totals();
}

final weighSessionProvider =
    StateNotifierProvider<WeighSessionNotifier, List<LoggedComponent>>(
  (ref) => WeighSessionNotifier(),
);

final mealTotalsProvider = Provider<MealTotals>((ref) {
  ref.watch(weighSessionProvider);
  return ref.watch(weighSessionProvider.notifier).totals();
});

// ---------------------------------------------------------------------------
// Meals
// ---------------------------------------------------------------------------

/// The local calendar day, refreshed at midnight so "today" rolls over while
/// the app is open.
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final untilMidnight = today.add(const Duration(days: 1)).difference(now) +
      const Duration(seconds: 1);
  final timer = Timer(untilMidnight, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return today;
});

/// Today's meals, oldest first, straight from SQLite.
final todaysMealsProvider = StreamProvider<List<LoggedMeal>>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  final day = ref.watch(todayProvider);
  yield* s.meals.watchMealsForDay(day);
});

final todaysTotalsProvider = Provider<MealTotals>((ref) {
  final meals = ref.watch(todaysMealsProvider).valueOrNull ?? const [];
  return MealTotals.from([for (final m in meals) ...m.components]);
});

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

/// Body measurement history, newest last.
final bodyHistoryProvider =
    StreamProvider<List<BodyCompositionResult>>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  yield* s.body.watchHistory();
});

final latestBodyMeasurementProvider = Provider<BodyCompositionResult?>((ref) {
  final history = ref.watch(bodyHistoryProvider).valueOrNull ?? const [];
  return history.isEmpty ? null : history.last;
});

/// The smoothed trend the Body screen leads with.
///
/// Published limits of agreement for foot-to-foot bioimpedance run to roughly
/// six kilograms of fat mass at the individual level, while day-to-day
/// repeatability is under one. Large bias, small noise — exactly the case where
/// a trend line is informative and a single reading is not. So the app shows the
/// median first and today's raw figure underneath it.
final bodyFatTrendProvider = Provider<double?>((ref) {
  final history = ref.watch(bodyHistoryProvider).valueOrNull ?? const [];
  final series = <({DateTime at, double value})>[];
  for (final r in history) {
    final m = r.metric('bodyFatPercent');
    if (m != null && m.derived == Derived.predicted) {
      series.add((at: r.takenAt, value: m.value));
    }
  }
  if (series.isEmpty) return null;
  return const TrendSmoother().rollingMedian(series, asOf: DateTime.now());
});

final weightTrendRateProvider = Provider<double?>((ref) {
  final history = ref.watch(bodyHistoryProvider).valueOrNull ?? const [];
  final series = [
    for (final r in history) (at: r.takenAt, value: r.weightKg),
  ];
  return const TrendSmoother(windowDays: 21)
      .weeklyRate(series, asOf: DateTime.now());
});

/// Weight as a series for the chart: every reading, plus the rolling median
/// on each reading's day.
final weightSeriesProvider = Provider<List<({DateTime at, double value})>>(
  (ref) {
    final history = ref.watch(bodyHistoryProvider).valueOrNull ?? const [];
    return [for (final r in history) (at: r.takenAt, value: r.weightKg)];
  },
);

// ---------------------------------------------------------------------------
// Energy target
// ---------------------------------------------------------------------------

/// Today's target. Derived from the most recent body measurement when there is
/// one — a fat-free-mass-based resting rate beats an anthropometric one — and
/// from Mifflin-St Jeor otherwise.
final dailyTargetProvider = Provider<EnergyTarget?>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) return null;
  final latest = ref.watch(latestBodyMeasurementProvider);

  final input = BiaInput(
    heightCm: profile.heightCm,
    weightKg: latest?.weightKg ?? 75,
    ageYears: profile.ageYears,
    sex: profile.sex,
  );

  final ffm = latest?.metric('fatFreeMass')?.value;
  final resting =
      ffm != null ? rmrCunningham1980(ffm) : bmrMifflinStJeor(input);

  final maintenance = tdee(
    restingKcal: resting.value,
    activity: profile.activity,
  );

  return EnergyTarget(
    kcal: maintenance.round(),
    basis: ffm != null
        ? 'From your fat-free mass (${resting.equation.citation})'
        : 'From height, weight and age (${resting.equation.citation})',
    proteinG: (input.weightKg * 1.6).round(),
    fatG: (maintenance * 0.28 / 9).round(),
  );
});

class EnergyTarget {
  const EnergyTarget({
    required this.kcal,
    required this.basis,
    this.proteinG,
    this.fatG,
  });

  final int kcal;
  final String basis;
  final int? proteinG;
  final int? fatG;

  int get carbG {
    final remaining = kcal - ((proteinG ?? 0) * 4) - ((fatG ?? 0) * 9);
    return (remaining / 4).round().clamp(0, 1000);
  }
}

// ---------------------------------------------------------------------------
// Sync status
// ---------------------------------------------------------------------------

/// The last completed sync attempt. Null until one has run, or forever when
/// there is no backend configured.
final syncReportProvider = StreamProvider<SyncReport?>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  final sync = s.sync;
  if (sync == null) {
    yield null;
    return;
  }
  yield sync.lastReport;
  yield* sync.reports;
});

/// How many meals are on this phone only.
final unsyncedMealCountProvider = StreamProvider<int>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  yield* s.meals.watchUnsyncedCount();
});
