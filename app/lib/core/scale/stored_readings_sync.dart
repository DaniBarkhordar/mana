/// Catching up on the weigh-ins a body scale took while the phone was away.
///
/// The scale keeps a few readings in its own memory. After every connect the
/// app asks for them, keeps the ones it can vouch for, stores each one
/// exactly as a live reading would have been stored, and only then tells the
/// scale it may forget them.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/body_reading_recorder.dart';
import '../data/providers.dart';
import '../data/repositories/body_repository.dart';
import '../data/repositories/profile_repository.dart';
import 'scale_driver.dart';

/// Pure: the rules, with the clock and every dependency injected.
class StoredReadingsSync {
  StoredReadingsSync({
    required this.driver,
    required this.body,
    required this.profiles,
    required this.source,
    this.pairedAt,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ScaleDriver driver;
  final BodyRepository body;
  final ProfileRepository profiles;

  /// The observation source label — the same one the live recorder uses, so
  /// a caught-up reading is indistinguishable in the store from a live one.
  final String source;

  /// When this scale became the user's. A reading stamped before that was
  /// taken by whoever owned the scale before, or by a flatmate stepping on
  /// it in the shop, and is not this user's data. Null (a pairing made
  /// before this was recorded, or the demo scale) sets no lower bound.
  final DateTime? pairedAt;

  final DateTime Function() _now;

  /// A reading later than now plus this is from a scale whose clock was never
  /// set, or was set wrong after a battery change. Five minutes covers a
  /// phone and a scale disagreeing by an honest amount; anything more is
  /// not a time we can put on a chart.
  static const clockSlack = Duration(minutes: 5);

  /// A stored row within this of a stored reading's stamp is the same
  /// weigh-in, already recorded live. The scale reports whole seconds and
  /// a live reading is stamped by the phone as it arrives, so the two stamps
  /// for one step-on can differ by a few seconds; a minute is generous
  /// without ever merging two real weigh-ins, which are minutes apart at the
  /// very least.
  static const duplicateWindow = Duration(seconds: 60);

  /// Fetches, filters, stores. Returns how many readings were stored.
  ///
  /// The scale is only told to clear its memory once every reading that
  /// should be stored has been, and never while a profile is missing (the
  /// readings would be lost, not deferred). A crash between fetch and store
  /// therefore leaves the readings on the scale for the next connect.
  Future<int> run() async {
    final readings = await driver.fetchStoredReadings();
    if (readings.isEmpty) return 0;

    final now = _now();
    final horizon = now.add(clockSlack);
    var stored = 0;
    var deferred = 0;
    for (final r in readings) {
      final paired = pairedAt;
      if (paired != null && r.at.isBefore(paired)) continue;
      if (r.at.isAfter(horizon)) continue;
      if (await body.hasReadingNear(r.at, within: duplicateWindow)) continue;
      final id = await recordBodyReading(
        profiles: profiles,
        body: body,
        kg: r.kg,
        at: r.at,
        impedanceOhm: r.impedanceOhm,
        source: source,
        driverName: driver.driverName,
      );
      if (id == null) {
        deferred++;
      } else {
        stored++;
      }
    }
    if (deferred == 0) await driver.clearStoredReadings();
    return stored;
  }
}

/// One completed catch-up, for the shell's message. A new instance per run so
/// two runs that both stored three readings are both announced.
class StoredReadingsCatchUp {
  const StoredReadingsCatchUp({required this.count, required this.at});

  final int count;
  final DateTime at;

  String get message => count == 1
      ? 'Caught up: 1 reading from your scale'
      : 'Caught up: $count readings from your scale';
}

/// The most recent catch-up that stored something. The shell listens and
/// shows a SnackBar; nothing else reads it.
final storedReadingsCaughtUpProvider =
    StateProvider<StoredReadingsCatchUp?>((ref) => null);

/// Runs a catch-up every time the body scale comes up. Kept alive by the
/// shell, next to the live recorder.
///
/// The radio is left exactly as the coordinator left it: the live path keeps
/// the body scale connected after a reading, and so does this. Disconnecting
/// here would race the coordinator's own hand-overs.
final storedReadingsSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<ScaleConnectionState>>(
    bodyConnectionProvider,
    (previous, next) {
      final wasConnected =
          previous?.valueOrNull == ScaleConnectionState.connected;
      if (next.valueOrNull != ScaleConnectionState.connected || wasConnected) {
        return;
      }
      unawaited(_catchUp(ref));
    },
  );
});

Future<void> _catchUp(Ref ref) async {
  try {
    final services = await ref.read(appServicesProvider.future);
    final driver = ref.read(bodyScaleDriverProvider);
    final store = await ref.read(scalePairingStoreProvider.future);
    final paired = await store.read(ScaleKind.body);
    final sync = StoredReadingsSync(
      driver: driver,
      body: services.body,
      profiles: services.profiles,
      source: observationSourceFor(driver, ScaleKind.body),
      pairedAt: paired?.pairedAt,
    );
    final count = await sync.run();
    if (count == 0) return;
    ref.read(storedReadingsCaughtUpProvider.notifier).state =
        StoredReadingsCatchUp(count: count, at: DateTime.now());
  } on Object {
    // The scale dropped the link mid-fetch, or the SDK declined. Nothing was
    // cleared, so the next connect starts the same catch-up again.
  }
}
