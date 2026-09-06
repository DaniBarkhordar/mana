/// Body readings: the raw scale output, the derived composition figures with
/// their provenance, and the observation rows that feed the general store.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../bia/body_composition.dart';
import '../../bia/equations.dart';
import '../db/database.dart';
import '../models.dart';
import 'observation_repository.dart';

class BodyRepository {
  BodyRepository(this._db, this._observations);

  final AppDatabase _db;
  final ObservationRepository _observations;
  static const _engine = BodyCompositionEngine();

  /// History, oldest first, rebuilt from the stored inputs.
  Stream<List<BodyCompositionResult>> watchHistory({int limit = 400}) {
    final q = _db.select(_db.bodyMeasurements)
      ..where((b) => b.deletedAt.isNull())
      ..orderBy([(b) => OrderingTerm.desc(b.takenAt)])
      ..limit(limit);
    return q.watch().map(
          (rows) => rows.reversed.map(BodyMeasurementCodec.fromRow).toList(),
        );
  }

  /// Stores one reading. [input] is the exact set of numbers the engine ran
  /// on, so height, age and sex are snapshotted with the row.
  Future<String> record({
    required BodyCompositionResult result,
    required BiaInput input,
    required String source,
    Map<String, Object?>? raw,
    String? deviceId,
  }) async {
    final userId = await _db.localUserId();
    final now = DateTime.now().toUtc();
    final id = AppDatabase.newId();

    await _db.transaction(() async {
      await _db.into(_db.bodyMeasurements).insert(
            BodyMeasurementCodec.toCompanion(
              id: id,
              userId: userId,
              result: result,
              input: input,
              deviceId: deviceId,
              raw: raw,
              now: now,
            ),
          );

      final takenAt = result.takenAt;
      await _observations.record(
        kind: 'weight_kg',
        value: input.weightKg,
        unit: 'kg',
        source: source,
        takenAt: takenAt,
        confidence: 'measured',
        deviceId: deviceId,
        raw: raw,
      );
      final r = input.resistanceOhm;
      if (r != null && r > 0) {
        await _observations.record(
          kind: 'impedance_ohm',
          value: r,
          unit: 'ohm',
          source: source,
          takenAt: takenAt,
          confidence: 'measured',
          deviceId: deviceId,
        );
      }
      final fat = result.metric('bodyFatPercent');
      if (fat != null && fat.derived == Derived.predicted) {
        await _observations.record(
          kind: 'body_fat_pct',
          value: fat.value,
          unit: '%',
          source: source,
          takenAt: takenAt,
          method: fat.equation?.name,
          confidence: BodyMeasurementCodec.encodeConfidence(result.confidence),
          deviceId: deviceId,
        );
      }
    });
    return id;
  }

  Future<void> delete(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.bodyMeasurements)..where((b) => b.id.equals(id)))
        .write(
      BodyMeasurementsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncedAt: const Value(null),
      ),
    );
  }

  /// Rebuilds a result exactly as the engine would compute it today.
  static BodyCompositionResult recompute(
    BiaInput input,
    DateTime takenAt, {
    MeasurementContext context = const MeasurementContext(),
  }) =>
      _engine.evaluate(input: input, takenAt: takenAt, context: context);
}

/// Maps between [BodyCompositionResult] and the `body_measurements` row.
///
/// Reading back re-runs the engine on the snapshotted inputs, which is exact
/// while the engine is unchanged. If the stored equation differs from the one
/// the engine would choose now — the equations were revised — the stored
/// figures win and the reading says so, because a change of equation must
/// never silently rewrite a user's history.
class BodyMeasurementCodec {
  const BodyMeasurementCodec._();

  static BodyMeasurementsCompanion toCompanion({
    required String id,
    required String userId,
    required BodyCompositionResult result,
    required BiaInput input,
    required DateTime now,
    String? deviceId,
    Map<String, Object?>? raw,
  }) {
    final ffm = result.metric('fatFreeMass');
    final fat = result.metric('bodyFatPercent');
    final equation = ffm?.equation ?? fat?.equation;
    return BodyMeasurementsCompanion.insert(
      id: id,
      userId: userId,
      deviceId: Value(deviceId),
      takenAt: result.takenAt.toUtc(),
      weightKg: input.weightKg,
      impedanceOhm: Value(input.resistanceOhm),
      reactanceOhm: Value(input.reactanceOhm),
      segmentalRaw: Value(
        raw == null || raw['segmental'] == null
            ? null
            : jsonEncode(raw['segmental']),
      ),
      heightCmAtTime: Value(input.heightCm),
      ageYearsAtTime: Value(input.ageYears),
      sexAtTime: Value(encodeSex(input.sex)),
      fatFreeMassKg: Value(ffm?.value),
      bodyFatPercent: Value(fat?.value),
      totalBodyWaterL: Value(result.metric('totalBodyWater')?.value),
      skeletalMuscleKg: Value(result.metric('skeletalMuscleMass')?.value),
      restingKcal: Value(result.metric('restingEnergy')?.value.round()),
      equation: Value(equation?.name),
      confidence: Value(encodeConfidence(result.confidence)),
      context: Value(jsonEncode(encodeContext(result.context))),
      notes: Value(jsonEncode(result.notes)),
      createdAt: now,
      updatedAt: now,
    );
  }

  static BodyCompositionResult fromRow(BodyMeasurement row) {
    final sex = decodeSex(row.sexAtTime);
    final height = row.heightCmAtTime;
    final age = row.ageYearsAtTime;
    final takenAt = row.takenAt.toLocal();
    final notes = _decodeNotes(row.notes);

    if (sex != null && height != null && age != null) {
      final input = BiaInput(
        heightCm: height,
        weightKg: row.weightKg,
        ageYears: age,
        sex: sex,
        resistanceOhm: row.impedanceOhm,
        reactanceOhm: row.reactanceOhm,
      );
      final recomputed = BodyRepository.recompute(
        input,
        takenAt,
        context: decodeContext(row.context),
      );
      final recomputedEquation = (recomputed.metric('fatFreeMass') ??
              recomputed.metric('bodyFatPercent'))
          ?.equation
          ?.name;
      if (row.equation == null || row.equation == recomputedEquation) {
        return BodyCompositionResult(
          takenAt: takenAt,
          weightKg: recomputed.weightKg,
          impedanceOhm: recomputed.impedanceOhm,
          confidence: recomputed.confidence,
          metrics: recomputed.metrics,
          notes: notes.isEmpty ? recomputed.notes : notes,
          context: recomputed.context,
        );
      }
    }
    return _fromStoredColumns(row, takenAt, notes);
  }

  /// The stored figures, as they were shown at the time.
  static BodyCompositionResult _fromStoredColumns(
    BodyMeasurement row,
    DateTime takenAt,
    List<String> notes,
  ) {
    final equation =
        BiaEquation.values.where((e) => e.name == row.equation).firstOrNull;
    final metrics = <Metric>[
      Metric(
        key: 'weight',
        label: 'Weight',
        value: row.weightKg,
        unit: 'kg',
        derived: Derived.predicted,
        uncertainty: 0.1,
      ),
    ];
    final h = row.heightCmAtTime;
    if (h != null && h > 0) {
      metrics.add(
        Metric(
          key: 'bmi',
          label: 'BMI',
          value: row.weightKg / ((h / 100) * (h / 100)),
          unit: '',
          derived: Derived.predicted,
        ),
      );
    }
    void add(String key, String label, double? v, String unit) {
      if (v == null) return;
      metrics.add(
        Metric(
          key: key,
          label: label,
          value: v,
          unit: unit,
          derived: Derived.predicted,
          equation: equation,
        ),
      );
    }

    add('fatFreeMass', 'Fat-free mass', row.fatFreeMassKg, 'kg');
    add('bodyFatPercent', 'Body fat', row.bodyFatPercent, '%');
    if (row.fatFreeMassKg != null) {
      add('fatMass', 'Fat mass', row.weightKg - row.fatFreeMassKg!, 'kg');
    }
    add('totalBodyWater', 'Body water', row.totalBodyWaterL, 'L');
    add('skeletalMuscleMass', 'Skeletal muscle', row.skeletalMuscleKg, 'kg');
    add(
      'restingEnergy',
      'Resting energy',
      row.restingKcal?.toDouble(),
      'kcal/day',
    );

    return BodyCompositionResult(
      takenAt: takenAt,
      weightKg: row.weightKg,
      impedanceOhm: row.impedanceOhm,
      confidence: decodeConfidence(row.confidence),
      metrics: metrics,
      context: decodeContext(row.context),
      notes: [
        ...notes,
        'Worked out when it was taken, with '
            '${equation?.citation ?? 'an earlier method'}. Shown as it was.',
      ],
    );
  }

  static String encodeConfidence(ReadingConfidence c) => switch (c) {
        ReadingConfidence.good => 'good',
        ReadingConfidence.fair => 'fair',
        ReadingConfidence.weightOnly => 'weight_only',
      };

  static ReadingConfidence decodeConfidence(String s) => switch (s) {
        'fair' => ReadingConfidence.fair,
        'weight_only' => ReadingConfidence.weightOnly,
        _ => ReadingConfidence.good,
      };

  static Map<String, Object?> encodeContext(MeasurementContext c) => {
        'morning_fasted': c.morningFasted,
        'after_exercise': c.afterExercise,
        'after_alcohol': c.afterAlcohol,
        'hours_since_last_meal': c.hoursSinceLastMeal,
      };

  static MeasurementContext decodeContext(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map) return const MeasurementContext();
    return MeasurementContext(
      morningFasted: decoded['morning_fasted'] as bool?,
      afterExercise: decoded['after_exercise'] == true,
      afterAlcohol: decoded['after_alcohol'] == true,
      hoursSinceLastMeal:
          (decoded['hours_since_last_meal'] as num?)?.toDouble(),
    );
  }

  static List<String> _decodeNotes(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList();
  }
}
