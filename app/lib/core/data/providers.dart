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
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';
import '../bia/body_composition.dart';
import '../billing/entitlements.dart';
import '../bia/equations.dart';
import '../food/food_catalog.dart';
import '../health/health_importer.dart';
import '../food/food_identifier.dart';
import '../food/food_search.dart';
import '../food/open_food_facts.dart';
import '../food/starter_foods.dart';
import '../nutrition/models.dart';
import '../nutrition/portion.dart';
import '../scale/lefu_driver.dart';
import '../scale/pairing.dart';
import '../scale/scale_driver.dart';
import 'account_actions.dart';
import 'db/database.dart';
import 'models.dart';
import 'repositories/body_repository.dart';
import 'repositories/meal_repository.dart';
import 'repositories/observation_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/user_food_repository.dart';
import 'sync/supabase_sync_remote.dart';
import 'sync/sync_engine.dart';
import 'sync/sync_scheduler.dart';

export '../auth/auth_service.dart'
    show
        AccountKind,
        AccountStatus,
        AuthService,
        IdentityProvider,
        SignInCancelled;
export '../billing/entitlements.dart'
    show
        BillingConfig,
        EntitlementService,
        PlusOffer,
        PlusPeriod,
        PlusStatus,
        PurchaseCancelled;
export '../health/health_importer.dart' show HealthImporter, HealthKind;
export 'account_actions.dart' show AccountActions, DataExporter;
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
    required this.userFoods,
    this.sync,
    this.supabase,
  });

  /// Everything in memory: tests and previews.
  factory AppServices.inMemory({SyncScheduler? sync}) =>
      AppServices.over(AppDatabase.memory(), sync: sync);

  factory AppServices.over(
    AppDatabase db, {
    SyncScheduler? sync,
    SupabaseClient? supabase,
  }) {
    final observations = ObservationRepository(db);
    return AppServices(
      db: db,
      profiles: ProfileRepository(db),
      meals: MealRepository(db),
      body: BodyRepository(db, observations),
      observations: observations,
      userFoods: UserFoodRepository(db),
      sync: sync,
      supabase: supabase,
    );
  }

  final AppDatabase db;
  final ProfileRepository profiles;
  final MealRepository meals;
  final BodyRepository body;
  final ObservationRepository observations;
  final UserFoodRepository userFoods;

  /// Null when no backend is configured: the app is local-only.
  final SyncScheduler? sync;

  /// The backend client, when one was initialised. Used for the vision
  /// function; never for reading health data directly (sync does that).
  final SupabaseClient? supabase;

  bool get canSync => sync != null;
}

/// Which AI provider the vision function is deployed against, for the
/// consent text. Set at build time to match `VISION_PROVIDER` on the server
/// (`--dart-define=VISION_PROVIDER="Google (Gemini)"` for a Gemini
/// deployment); the default matches the function's default, Anthropic.
class VisionConfig {
  const VisionConfig._();

  static const providerName = String.fromEnvironment(
    'VISION_PROVIDER',
    defaultValue: 'Anthropic (Claude)',
  );
}

/// Vendor scale credentials, injected at build time and never committed:
///
/// ```
/// flutter run --dart-define=LEFU_APP_KEY=... --dart-define=LEFU_APP_SECRET=...
/// ```
///
/// plus the licence file the vendor's open platform issues, copied to
/// `assets/lefu.config` (git-ignored). Without all three the app runs on the
/// simulated scale and Settings says so. The demo credentials in the vendored
/// demos are for a desk, never for a build that leaves it (docs/10-sdk.md).
class LefuConfig {
  const LefuConfig._();

  static const appKey = String.fromEnvironment('LEFU_APP_KEY');
  static const appSecret = String.fromEnvironment('LEFU_APP_SECRET');
  static const configAsset = 'assets/lefu.config';

  static bool get isConfigured => appKey.isNotEmpty && appSecret.isNotEmpty;

  static LefuCredentials get credentials => const LefuCredentials(
        appKey: appKey,
        appSecret: appSecret,
        configAsset: configAsset,
      );
}

/// Opens the database and, when configured, the backend. Tolerant on purpose:
/// a cold start with no network must still reach a usable screen, so any
/// failure to reach Supabase leaves the app local-only rather than broken.
final appServicesProvider = FutureProvider<AppServices>((ref) async {
  final db = await AppDatabase.open();
  await db.localUserId();

  SyncScheduler? sync;
  SupabaseClient? supabase;
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      supabase = Supabase.instance.client;
      final engine = SyncEngine(db: db, remote: SupabaseSyncRemote(supabase));
      sync = SyncScheduler(engine: engine, db: db)..start();
    } on Object {
      sync = null;
      supabase = null;
    }
  }

  ref.onDispose(() {
    sync?.stop();
    db.close();
  });
  return AppServices.over(db, sync: sync, supabase: supabase);
});

// ---------------------------------------------------------------------------
// Account
// ---------------------------------------------------------------------------

final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final s = await ref.watch(appServicesProvider.future);
  final client = s.supabase;
  return AuthService(
    client == null ? const NoAuthBackend() : SupabaseAuthBackend(client),
    s.db,
  );
});

/// Who this phone is signed in as. `none` in a local-only build.
final accountStatusProvider = StreamProvider<AccountStatus>((ref) async* {
  final auth = await ref.watch(authServiceProvider.future);
  yield auth.status;
  yield* auth.changes;
});

final accountActionsProvider = FutureProvider<AccountActions>((ref) async {
  final s = await ref.watch(appServicesProvider.future);
  return AccountActions(db: s.db, profiles: s.profiles, supabase: s.supabase);
});

final dataExporterProvider = FutureProvider<DataExporter>((ref) async {
  final s = await ref.watch(appServicesProvider.future);
  return DataExporter(s.db);
});

// ---------------------------------------------------------------------------
// Plus
// ---------------------------------------------------------------------------

/// The store's view of Plus. Identified with the account's user id so the
/// webhook can name the user and a purchase follows a sign-in to a new phone.
final entitlementServiceProvider =
    FutureProvider<EntitlementService>((ref) async {
  final service = EntitlementService(
    BillingConfig.isConfigured ? RevenueCatBackend() : const NoBillingBackend(),
    enabled: BillingConfig.isConfigured,
  );
  ref.onDispose(service.dispose);
  final account = await ref.watch(accountStatusProvider.future);
  if (account.userId != null) {
    try {
      await service.identify(account.userId!);
    } on Object {
      // The store is unreachable; Plus reads as free until it is.
    }
  }
  return service;
});

final plusStatusProvider = StreamProvider<PlusStatus>((ref) async* {
  final service = await ref.watch(entitlementServiceProvider.future);
  yield service.status;
  yield* service.changes;
});

// ---------------------------------------------------------------------------
// Wearables
// ---------------------------------------------------------------------------

/// Apple Health / Health Connect, behind the importer. Tests override the
/// gateway.
final healthGatewayProvider =
    Provider<HealthGateway>((ref) => PlatformHealthGateway());

final healthImporterProvider = FutureProvider<HealthImporter>((ref) async {
  final s = await ref.watch(appServicesProvider.future);
  return HealthImporter(
    gateway: ref.watch(healthGatewayProvider),
    observations: s.observations,
    db: s.db,
  );
});

final healthConnectedProvider = StreamProvider<bool>((ref) async* {
  final importer = await ref.watch(healthImporterProvider.future);
  yield* importer.watchConnected();
});

final healthWritesWeightProvider = StreamProvider<bool>((ref) async* {
  final importer = await ref.watch(healthImporterProvider.future);
  yield* importer.watchWritesWeight();
});

final healthLastImportProvider = StreamProvider<DateTime?>((ref) async* {
  final importer = await ref.watch(healthImporterProvider.future);
  yield* importer.watchLastImport();
});

/// Every source that has written an observation, for the Sources screen.
final observationSourcesProvider = FutureProvider<List<String>>((ref) async {
  final s = await ref.watch(appServicesProvider.future);
  // Re-read when anything changes.
  ref.watch(bodyHistoryProvider);
  return s.observations.sources();
});

/// The latest observation of one kind: "last night's sleep", "yesterday's
/// resting heart rate".
final latestObservationProvider =
    StreamProvider.family<ObservationPoint?, String>((ref, kind) async* {
  final s = await ref.watch(appServicesProvider.future);
  yield* s.observations
      .watchSeries(kind)
      .map((series) => series.isEmpty ? null : series.last);
});

/// Pulls new wearable data when the app comes to the foreground, if the
/// store is connected. Kept alive by the shell.
final healthRefreshProvider = Provider<void>((ref) {
  final connected = ref.watch(healthConnectedProvider).valueOrNull ?? false;
  if (!connected) return;
  unawaited(() async {
    try {
      final importer = await ref.read(healthImporterProvider.future);
      await importer.importSince();
    } on Object {
      // Not available right now; the next launch tries again.
    }
  }());
});

// ---------------------------------------------------------------------------
// Foods
// ---------------------------------------------------------------------------

/// The shipped catalogue (CoFID + USDA), opened once. Null in a build that
/// carries no `assets/food/core.sqlite`; search then covers the user's own
/// foods plus a small starter list, and the sheet says so.
final foodCatalogProvider = FutureProvider<FoodCatalog?>((ref) async {
  final catalog = await FoodCatalog.openAsset();
  ref.onDispose(() => catalog?.close());
  return catalog;
});

final foodSearchProvider = FutureProvider<FoodSearch>((ref) async {
  final services = await ref.watch(appServicesProvider.future);
  final catalog = await ref.watch(foodCatalogProvider.future);
  return FoodSearch(
    catalog: catalog,
    userFoods: services.userFoods,
    fallback: starterFoods,
  );
});

final openFoodFactsProvider = Provider<OpenFoodFactsClient>((ref) {
  final client = OpenFoodFactsClient();
  ref.onDispose(client.close);
  return client;
});

/// Photo identification through the Edge Function, or an honest "not
/// available" in a build with no backend. Tests override this with a fake.
final foodIdentifierProvider = Provider<FoodIdentifier>((ref) {
  final client = ref.watch(appServicesProvider).valueOrNull?.supabase;
  if (client == null) return const UnavailableFoodIdentifier();
  return SupabaseFoodIdentifier(client);
});

final foodMatcherProvider = FutureProvider<FoodMatcher>((ref) async {
  return FoodMatcher(await ref.watch(foodSearchProvider.future));
});

/// Takes a photo with the system camera and returns its bytes, or null when
/// the user backs out. Overridden in tests to inject an image.
final photoCaptureProvider = Provider<Future<Uint8List?> Function()>((ref) {
  return () async {
    // Android: a CAMERA permission declared in the manifest (the barcode
    // scanner needs it) must also be held at runtime before the camera
    // intent will open.
    final status = await Permission.camera.request();
    if (!status.isGranted && !status.isLimited) return null;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 88,
    );
    return picked?.readAsBytes();
  };
});

/// Which tab the shell shows. A provider so a card on one tab can open
/// another (Today's body card opens Body).
final shellIndexProvider = StateProvider<int>((ref) => 0);

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

/// Whether photos may go to the AI provider. Asked separately, before the
/// first scan, and switchable in Settings.
final photoConsentProvider = StreamProvider<ConsentRecord?>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  yield* s.profiles.watchLatestConsent(ConsentRecord.photoRecognition);
});

// ---------------------------------------------------------------------------
// Scales
// ---------------------------------------------------------------------------

/// Which driver is in play.
///
/// The vendor driver when the build carries credentials and the user has not
/// switched to the demo scale; the simulated driver otherwise. The simulated
/// driver stays in the release build behind that switch so App Review can walk
/// the whole flow without hardware (CLAUDE.md rule 9). Nothing else in the
/// app knows which one it got — that is the point of the abstraction.
final demoScaleProvider = StreamProvider<bool>((ref) async* {
  if (!LefuConfig.isConfigured) {
    yield true;
    return;
  }
  final s = await ref.watch(appServicesProvider.future);
  yield* s.db.watchStateValue(demoScaleKey).map((v) => v == 'true');
});

const demoScaleKey = 'demo_scale';

bool _useDemoScale(Ref ref) =>
    !LefuConfig.isConfigured ||
    (ref.watch(demoScaleProvider).valueOrNull ?? false);

final bodyScaleDriverProvider = Provider<ScaleDriver>((ref) {
  final ScaleDriver driver = _useDemoScale(ref)
      ? SimulatedScaleDriver(kind: ScaleKind.body)
      : LefuScaleDriver(
          channel: PpBluetoothKitChannel(ScaleKind.body),
          credentials: LefuConfig.credentials,
          kind: ScaleKind.body,
        );
  ref.onDispose(driver.dispose);
  return driver;
});

final kitchenScaleDriverProvider = Provider<ScaleDriver>((ref) {
  final ScaleDriver driver = _useDemoScale(ref)
      ? SimulatedScaleDriver(kind: ScaleKind.kitchen)
      : LefuScaleDriver(
          channel: PpBluetoothKitChannel(ScaleKind.kitchen),
          credentials: LefuConfig.credentials,
          kind: ScaleKind.kitchen,
        );
  ref.onDispose(driver.dispose);
  return driver;
});

/// Where pairings live.
final scalePairingStoreProvider =
    FutureProvider<ScalePairingStore>((ref) async {
  final s = await ref.watch(appServicesProvider.future);
  return ScalePairingStore(s.db);
});

final pairedScaleProvider =
    StreamProvider.family<PairedScale?, ScaleKind>((ref, kind) async* {
  final store = await ref.watch(scalePairingStoreProvider.future);
  yield* store.watch(kind);
});

/// Which scale the user is looking at. The Weigh food screen claims the
/// kitchen scale while it is open; everything else wants the body scale.
final scaleFocusProvider = StateProvider<ScaleKind>((ref) => ScaleKind.body);

/// Owns the radio: connects the paired scale for the current focus and, on
/// exclusive drivers, releases the other one. Kept alive by the shell.
final scaleCoordinatorProvider =
    FutureProvider<ScaleConnectionCoordinator>((ref) async {
  final coordinator = ScaleConnectionCoordinator(
    body: ref.watch(bodyScaleDriverProvider),
    kitchen: ref.watch(kitchenScaleDriverProvider),
    pairing: await ref.watch(scalePairingStoreProvider.future),
  );
  ref.listen<ScaleKind>(scaleFocusProvider, (_, kind) {
    unawaited(coordinator.focusOn(kind));
  });
  return coordinator;
});

/// Connects both scales at startup: the simulated driver finds its demo
/// device; the vendor driver connects whatever was paired.
final scaleSessionProvider = FutureProvider<void>((ref) async {
  final coordinator = await ref.watch(scaleCoordinatorProvider.future);
  final demo = _useDemoScale(ref);
  if (demo) {
    // The demo scale has no pairing step: it is always there.
    for (final driver in [coordinator.body, coordinator.kitchen]) {
      unawaited(_autoConnect(driver));
    }
    return;
  }
  unawaited(coordinator.start());
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
    // Measured weight to Health, when asked. Never the demo scale's, never
    // the composition.
    if (driver is! SimulatedScaleDriver) {
      final importer = ref.read(healthImporterProvider).valueOrNull;
      await importer?.shareWeight(sample.kg, sample.at);
    }
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
