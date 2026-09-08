import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/data/providers/insight_providers.dart';
import 'package:mananu/core/insights/weekly_review.dart';
import 'package:mananu/features/progress/evening_tags_sheet.dart';

/// An evening tag is an observation like any other: kind `tag_*`, source
/// `diary`, value 1 or 0, unit `flag`. Written through the repository onto
/// an in-memory database and read back the way the providers read it.
void main() {
  late AppServices s;

  setUp(() => s = AppServices.inMemory());
  tearDown(() => s.db.close());

  Future<List<ObservationSample>> rows() async {
    final q = s.db.select(s.db.observations)
      ..orderBy([(o) => OrderingTerm.asc(o.takenAt)]);
    return [
      for (final r in await q.get())
        ObservationSample(
          kind: r.kind,
          value: r.value,
          unit: r.unit,
          source: r.source,
          takenAt: r.takenAt.toLocal(),
        ),
    ];
  }

  test('switching a tag on writes a diary observation', () async {
    final at = DateTime(2026, 9, 8, 22, 10);
    await EveningTagsSheet.setTag(s, 'tag_alcohol', on: true, at: at);

    final all = await rows();
    expect(all, hasLength(1));
    expect(all.single.kind, 'tag_alcohol');
    expect(all.single.source, 'diary');
    expect(all.single.unit, 'flag');
    expect(all.single.value, 1);
    expect(all.single.takenAt, at);
    expect(tagsOn(all, at), {'tag_alcohol'});
  });

  test('switching it off writes a 0 that supersedes the 1', () async {
    final day = DateTime(2026, 9, 8);
    await EveningTagsSheet.setTag(
      s,
      'tag_travel',
      on: true,
      at: day.add(const Duration(hours: 21)),
    );
    await EveningTagsSheet.setTag(
      s,
      'tag_travel',
      on: false,
      at: day.add(const Duration(hours: 22)),
    );
    await EveningTagsSheet.setTag(
      s,
      'tag_illness',
      on: true,
      at: day.add(const Duration(hours: 22)),
    );

    final all = await rows();
    expect(all, hasLength(3));
    expect(all.every((o) => o.source == 'diary'), isTrue);
    expect(tagsOn(all, day), {'tag_illness'});
    // Another day's tags are another day's.
    expect(tagsOn(all, day.add(const Duration(days: 1))), isEmpty);
  });

  test('the four tags carry their own kinds', () {
    expect(EveningTagsSheet.labels.keys, [
      'tag_alcohol',
      'tag_caffeine_late',
      'tag_illness',
      'tag_travel',
    ]);
  });
}
