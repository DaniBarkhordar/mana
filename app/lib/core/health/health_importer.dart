/// Wearable data in, from day one.
///
/// A ring, a watch or a band already writes to Apple Health or Health
/// Connect. Mananu reads what is there — sleep, resting heart rate, HRV,
/// steps, workouts — and stores each value as an observation with its source
/// named, so last night's HRV sits on the same timeline as this morning's
/// body fat and the user can always see which device said what (CLAUDE.md
/// rule 7). Nothing here goes to an analytics or ad SDK (Apple 5.1.3(i)).
///
/// One thing goes back: measured weight. Body fat does not — it is a modelled
/// estimate, and writing a model's output into HealthKit as a measurement is
/// exactly what Apple 5.1.2(ii) forbids and what the honesty of the product
/// forbids.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:drift/drift.dart';
import 'package:health/health.dart';

import '../data/db/database.dart';
import '../data/repositories/observation_repository.dart';

/// What we read, in our own vocabulary. Each maps to an observation kind.
enum HealthKind {
  steps('steps', 'count'),
  restingHeartRate('resting_hr_bpm', 'bpm'),
  hrvSdnn('hrv_sdnn_ms', 'ms'),
  hrvRmssd('hrv_rmssd_ms', 'ms'),
  sleepAsleep('sleep_minutes', 'min'),
  workout('workout_minutes', 'min'),
  weight('weight_kg', 'kg');

  const HealthKind(this.observationKind, this.unit);

  final String observationKind;
  final String unit;
}

/// One sample as the platform hands it over, before any aggregation.
class HealthSample {
  const HealthSample({
    required this.kind,
    required this.value,
    required this.from,
    required this.to,
    required this.sourceName,
  });

  final HealthKind kind;
  final double value;
  final DateTime from;
  final DateTime to;

  /// The app or device that wrote it: "Oura", "Apple Watch", "WHOOP".
  final String sourceName;
}

/// The platform health store, behind an interface so the importer can be
/// tested without a phone.
abstract class HealthGateway {
  /// Which store this is: `apple_health` or `health_connect`.
  String get sourceId;

  /// Human name for Settings.
  String get displayName;

  /// True when the store exists on this device at all.
  Future<bool> isAvailable();

  Future<bool> requestAccess({required bool writeWeight});

  Future<List<HealthSample>> read({
    required List<HealthKind> kinds,
    required DateTime from,
    required DateTime to,
  });

  Future<bool> writeWeight(double kg, DateTime at);
}

/// Reads from Apple Health / Health Connect into observations, and writes
/// measured weight back when the user asked for that.
class HealthImporter {
  HealthImporter({
    required HealthGateway gateway,
    required ObservationRepository observations,
    required AppDatabase db,
  })  : _gateway = gateway,
        _observations = observations,
        _db = db;

  final HealthGateway _gateway;
  final ObservationRepository _observations;
  final AppDatabase _db;

  static const connectedKey = 'health_connected';
  static const writeWeightKey = 'health_write_weight';
  static const cursorKey = 'health_import_cursor';
  static const lastImportKey = 'health_last_import';

  static const readKinds = [
    HealthKind.steps,
    HealthKind.restingHeartRate,
    HealthKind.hrvSdnn,
    HealthKind.hrvRmssd,
    HealthKind.sleepAsleep,
    HealthKind.workout,
  ];

  HealthGateway get gateway => _gateway;

  Future<bool> get isConnected async =>
      await _db.stateValue(connectedKey) == 'true';

  Future<bool> get writesWeight async =>
      await _db.stateValue(writeWeightKey) == 'true';

  Stream<bool> watchConnected() =>
      _db.watchStateValue(connectedKey).map((v) => v == 'true');

  Stream<bool> watchWritesWeight() =>
      _db.watchStateValue(writeWeightKey).map((v) => v == 'true');

  Stream<DateTime?> watchLastImport() => _db
      .watchStateValue(lastImportKey)
      .map((v) => v == null ? null : DateTime.tryParse(v));

  /// Asks for access and, if granted, pulls the last [days]. Returns false
  /// when access was refused.
  Future<bool> connect({int days = 30, bool writeWeight = false}) async {
    final ok = await _gateway.requestAccess(writeWeight: writeWeight);
    if (!ok) return false;
    await _db.setStateValue(connectedKey, 'true');
    await _db.setStateValue(writeWeightKey, writeWeight ? 'true' : 'false');
    await importSince(DateTime.now().subtract(Duration(days: days)));
    return true;
  }

  Future<void> disconnect() async {
    await _db.setStateValue(connectedKey, 'false');
    await _db.setStateValue(writeWeightKey, 'false');
  }

  Future<void> setWriteWeight(bool on) async {
    if (on && !await _gateway.requestAccess(writeWeight: true)) return;
    await _db.setStateValue(writeWeightKey, on ? 'true' : 'false');
  }

  /// Pulls everything since the last import (or [from]), aggregates it into
  /// one observation per kind per day, and skips what is already stored.
  /// Returns how many observations were added.
  Future<int> importSince([DateTime? from]) async {
    final cursorRaw = await _db.stateValue(cursorKey);
    final cursor = cursorRaw == null ? null : DateTime.tryParse(cursorRaw);
    // Overlap by a day: sleep and HRV for "last night" land after midnight.
    final start =
        (from ?? cursor ?? DateTime.now().subtract(const Duration(days: 30)))
            .subtract(const Duration(days: 1));
    final now = DateTime.now();
    final samples = await _gateway.read(kinds: readKinds, from: start, to: now);
    final daily = aggregate(samples);

    var added = 0;
    for (final d in daily) {
      if (await _exists(d)) continue;
      await _observations.record(
        kind: d.kind.observationKind,
        value: d.value,
        unit: d.kind.unit,
        source: _gateway.sourceId,
        takenAt: d.at,
        method: 'imported',
        raw: {'sourceName': d.sourceName, 'samples': d.samples},
      );
      added += 1;
    }
    await _db.setStateValue(cursorKey, now.toUtc().toIso8601String());
    await _db.setStateValue(lastImportKey, now.toUtc().toIso8601String());
    return added;
  }

  Future<bool> _exists(DailyValue d) async {
    final q = _db.select(_db.observations)
      ..where(
        (o) =>
            o.kind.equals(d.kind.observationKind) &
            o.source.equals(_gateway.sourceId) &
            o.takenAt.equals(d.at.toUtc()) &
            o.deletedAt.isNull(),
      )
      ..limit(1);
    return (await q.get()).isNotEmpty;
  }

  /// A measured weight from the scale, into the health store, when enabled.
  /// Only weight: composition is modelled and stays in Mananu.
  Future<void> shareWeight(double kg, DateTime at) async {
    if (!await isConnected || !await writesWeight) return;
    try {
      await _gateway.writeWeight(kg, at);
    } on Object {
      // The store said no (permission revoked since). Nothing to surface: the
      // reading is safe in Mananu and Settings shows the switch.
    }
  }

  /// Pure: raw samples into one value per kind per local day.
  ///
  /// Steps and workouts sum over the day. Sleep sums over the *night*: a
  /// segment is filed under the day it ends, so a 23:30–07:10 sleep is
  /// Tuesday's, not Monday's. Resting heart rate and HRV take the day's
  /// median, since a wearable reports several and a single high reading is
  /// noise.
  static List<DailyValue> aggregate(List<HealthSample> samples) {
    final buckets = <String, List<HealthSample>>{};
    for (final s in samples) {
      final anchor = s.kind == HealthKind.sleepAsleep ? s.to : s.from;
      final local = anchor.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final key = '${s.kind.name}|${day.toIso8601String()}';
      buckets.putIfAbsent(key, () => []).add(s);
    }
    final out = <DailyValue>[];
    buckets.forEach((key, list) {
      final kind = list.first.kind;
      final dayIso = key.split('|').last;
      final day = DateTime.parse(dayIso);
      final values = list.map((s) => s.value).toList()..sort();
      final double value;
      switch (kind) {
        case HealthKind.steps:
        case HealthKind.workout:
        case HealthKind.sleepAsleep:
          value = values.fold(0.0, (a, b) => a + b);
        case HealthKind.restingHeartRate:
        case HealthKind.hrvSdnn:
        case HealthKind.hrvRmssd:
        case HealthKind.weight:
          value = values.length.isOdd
              ? values[values.length ~/ 2]
              : (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) /
                  2;
      }
      if (value <= 0) return;
      // Noon local: a daily figure, not a moment.
      out.add(
        DailyValue(
          kind: kind,
          at: day.add(const Duration(hours: 12)),
          value: double.parse(value.toStringAsFixed(2)),
          sourceName: list.first.sourceName,
          samples: list.length,
        ),
      );
    });
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }
}

class DailyValue {
  const DailyValue({
    required this.kind,
    required this.at,
    required this.value,
    required this.sourceName,
    required this.samples,
  });

  final HealthKind kind;
  final DateTime at;
  final double value;
  final String sourceName;
  final int samples;
}

/// The real store, through the `health` plugin.
class PlatformHealthGateway implements HealthGateway {
  PlatformHealthGateway();

  final Health _health = Health();
  bool _configured = false;

  @override
  String get sourceId => Platform.isIOS ? 'apple_health' : 'health_connect';

  @override
  String get displayName => Platform.isIOS ? 'Apple Health' : 'Health Connect';

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  static HealthDataType? _type(HealthKind kind) => switch (kind) {
        HealthKind.steps => HealthDataType.STEPS,
        HealthKind.restingHeartRate => HealthDataType.RESTING_HEART_RATE,
        // iOS reports SDNN; Health Connect reports RMSSD, which the plugin
        // (10.x) exposes under the same constant. Stored as separate kinds so
        // a chart never mixes the two.
        HealthKind.hrvSdnn =>
          Platform.isIOS ? HealthDataType.HEART_RATE_VARIABILITY_SDNN : null,
        HealthKind.hrvRmssd => Platform.isAndroid
            ? HealthDataType.HEART_RATE_VARIABILITY_SDNN
            : null,
        HealthKind.sleepAsleep => HealthDataType.SLEEP_ASLEEP,
        HealthKind.workout => HealthDataType.WORKOUT,
        HealthKind.weight => HealthDataType.WEIGHT,
      };

  static List<HealthDataType> _readTypes() => [
        for (final k in HealthImporter.readKinds)
          if (_type(k) != null) _type(k)!,
      ];

  @override
  Future<bool> isAvailable() async {
    await _configure();
    if (Platform.isIOS) return true;
    final status = await _health.getHealthConnectSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  @override
  Future<bool> requestAccess({required bool writeWeight}) async {
    await _configure();
    final types = [..._readTypes(), if (writeWeight) HealthDataType.WEIGHT];
    final permissions = [
      for (final _ in _readTypes()) HealthDataAccess.READ,
      if (writeWeight) HealthDataAccess.READ_WRITE,
    ];
    return _health.requestAuthorization(types, permissions: permissions);
  }

  @override
  Future<List<HealthSample>> read({
    required List<HealthKind> kinds,
    required DateTime from,
    required DateTime to,
  }) async {
    await _configure();
    final wanted = {for (final k in kinds) _type(k): k}..remove(null);
    final points = await _health.getHealthDataFromTypes(
      types: wanted.keys.whereType<HealthDataType>().toList(),
      startTime: from,
      endTime: to,
    );
    final out = <HealthSample>[];
    for (final p in points) {
      final kind = wanted[p.type];
      if (kind == null) continue;
      final double? value;
      final v = p.value;
      if (v is NumericHealthValue) {
        value = v.numericValue.toDouble();
      } else if (v is WorkoutHealthValue) {
        value = p.dateTo.difference(p.dateFrom).inMinutes.toDouble();
      } else {
        value = null;
      }
      if (value == null) continue;
      out.add(
        HealthSample(
          kind: kind,
          value: kind == HealthKind.sleepAsleep && v is NumericHealthValue
              ? p.dateTo.difference(p.dateFrom).inMinutes.toDouble()
              : value,
          from: p.dateFrom,
          to: p.dateTo,
          sourceName: p.sourceName,
        ),
      );
    }
    return out;
  }

  @override
  Future<bool> writeWeight(double kg, DateTime at) async {
    await _configure();
    return _health.writeHealthData(
      value: kg,
      type: HealthDataType.WEIGHT,
      unit: HealthDataUnit.KILOGRAM,
      startTime: at,
      endTime: at,
    );
  }
}
