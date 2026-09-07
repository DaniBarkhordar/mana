import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/db/database.dart';
import 'package:mananu/core/data/models.dart';
import 'package:mananu/core/data/repositories/profile_repository.dart';
import 'package:mananu/core/nutrition/energy_target.dart';

/// The goal fields on the profile: they round-trip through SQLite, default
/// sensibly when left out (the screenshot seed and older callers do), and
/// [ProfileRepository.saveGoal] leaves the measurement inputs alone.
void main() {
  late AppDatabase db;
  late ProfileRepository profiles;

  setUp(() {
    db = AppDatabase.memory();
    profiles = ProfileRepository(db);
  });

  tearDown(() => db.close());

  test('a save without goal fields stores the defaults', () async {
    await profiles.save(
      heightCm: 178,
      dateOfBirth: DateTime(1992, 7, 1),
      sex: Sex.male,
      activity: ActivityLevel.lowActive,
    );
    final p = (await profiles.currentProfile())!;
    expect(p.goal, GoalKind.maintain);
    expect(p.targetWeightKg, isNull);
    expect(p.paceKgPerWeek, isNull);
    expect(p.macroSplit, MacroSplit.balanced);
  });

  test('goal fields round-trip through the Postgres labels', () async {
    await profiles.save(
      heightCm: 178,
      dateOfBirth: DateTime(1992, 7, 1),
      sex: Sex.male,
      activity: ActivityLevel.lowActive,
      goal: GoalKind.lose,
      targetWeightKg: 74.5,
      paceKgPerWeek: 0.75,
      macroSplit: MacroSplit.highProtein,
    );
    final row = (await db.select(db.profiles).get()).single;
    expect(row.goal, 'lose');
    expect(row.macroSplit, 'high_protein');
    expect(row.targetWeightKg, 74.5);
    expect(row.paceKgPerWeek, 0.75);

    final p = (await profiles.watchProfile().first)!;
    expect(p.goal, GoalKind.lose);
    expect(p.targetWeightKg, 74.5);
    expect(p.paceKgPerWeek, 0.75);
    expect(p.macroSplit, MacroSplit.highProtein);
  });

  test('saveGoal changes the goal and nothing else, and marks for sync',
      () async {
    await profiles.save(
      heightCm: 178,
      dateOfBirth: DateTime(1992, 7, 1),
      sex: Sex.male,
      activity: ActivityLevel.active,
      displayName: 'Dan',
    );
    await db.customUpdate(
      "UPDATE profiles SET synced_at = '2026-01-01T00:00:00.000Z'",
    );
    final saved = await profiles.saveGoal(
      goal: GoalKind.gain,
      targetWeightKg: 84,
      paceKgPerWeek: 0.25,
      macroSplit: MacroSplit.lowCarb,
    );
    expect(saved, isNotNull);
    final p = (await profiles.currentProfile())!;
    expect(p.heightCm, 178);
    expect(p.activity, ActivityLevel.active);
    expect(p.displayName, 'Dan');
    expect(p.goal, GoalKind.gain);
    expect(p.targetWeightKg, 84);
    expect(p.paceKgPerWeek, 0.25);
    expect(p.macroSplit, MacroSplit.lowCarb);
    final rows = await db.select(db.profiles).get();
    expect(rows, hasLength(1));
    expect(rows.single.syncedAt, isNull);
  });

  test('saveGoal with no profile is a no-op', () async {
    expect(
      await profiles.saveGoal(
        goal: GoalKind.lose,
        targetWeightKg: 70,
        paceKgPerWeek: 0.5,
        macroSplit: MacroSplit.balanced,
      ),
      isNull,
    );
  });

  test('unknown labels decode to the defaults rather than throwing', () {
    expect(decodeGoal('bulk'), GoalKind.maintain);
    expect(decodeGoal(null), GoalKind.maintain);
    expect(decodeMacroSplit('keto'), MacroSplit.balanced);
    expect(encodeMacroSplit(MacroSplit.lowCarb), 'low_carb');
    expect(encodeGoal(GoalKind.gain), 'gain');
  });
}
