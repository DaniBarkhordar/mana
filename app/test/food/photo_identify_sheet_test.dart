import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/food/food_catalog.dart';
import 'package:mananu/core/food/food_identifier.dart';
import 'package:mananu/features/food/photo_identify_sheet.dart';
import 'package:mananu/theme/tokens.dart';

/// Answers with a fixed plate, and records what it was asked so the test can
/// prove the request carried context and never a quantity question.
class FakeIdentifier implements FoodIdentifier {
  FakeIdentifier(this.result);

  final IdentifyResult result;
  IdentifyRequest? lastRequest;

  @override
  Future<IdentifyResult> identify(IdentifyRequest request) async {
    lastRequest = request;
    return result;
  }
}

Uint8List _photoBytes() {
  final image = img.Image(width: 640, height: 480);
  img.fill(image, color: img.ColorRgb8(180, 140, 90));
  return Uint8List.fromList(img.encodeJpg(image, quality: 60));
}

void main() {
  late AppServices services;
  late FoodCatalog catalog;
  late FakeIdentifier identifier;

  setUp(() {
    services = AppServices.inMemory();
    catalog = FoodCatalog.inMemory();
    catalog.insert(
      id: 'cofid:rice-boiled',
      name: 'Rice, white, basmati, boiled',
      source: 'cofid',
      kcal: 130,
      isCooked: true,
    );
    catalog.insert(
      id: 'cofid:chicken-grilled',
      name: 'Chicken, breast, grilled, meat only',
      source: 'cofid',
      kcal: 148,
      isCooked: true,
    );
    identifier = FakeIdentifier(
      IdentifyResult.fromJson({
        'candidates': [
          {
            'name': 'Chicken tikka',
            'queries': ['chicken tikka', 'chicken breast grilled'],
            'confidence': 0.85,
            'massShare': 0.4,
            'cooked': true,
            'likelyAddedFat': 'ghee',
          },
          {
            'name': 'Basmati rice',
            'queries': ['rice basmati boiled'],
            'confidence': 0.9,
            'massShare': 0.5,
            'cooked': true,
          },
        ],
      }),
    );
  });

  tearDown(() async {
    catalog.close();
    await services.db.close();
  });

  Widget host({required Widget Function(BuildContext) open}) => ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
          foodCatalogProvider.overrideWith((ref) async => catalog),
          foodIdentifierProvider.overrideWithValue(identifier),
          photoCaptureProvider.overrideWithValue(() async => _photoBytes()),
        ],
        child: MaterialApp(
          theme: MananuTheme.light(),
          home: Builder(builder: open),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('asks for consent first, names the provider, and then scans',
      (tester) async {
    PhotoOutcome? outcome;
    await tester.pumpWidget(
      host(
        open: (context) => Center(
          child: FilledButton(
            onPressed: () async =>
                outcome = await PhotoIdentifySheet.show(context),
            child: const Text('Photo'),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Photo'));
    await settle(tester);

    expect(find.text('Photos and the AI provider'), findsOneWidget);
    expect(find.textContaining(VisionConfig.providerName), findsOneWidget);
    expect(identifier.lastRequest, isNull);

    await tester.tap(find.text('Allow photo recognition'));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    // Largest share first, matched to the catalogue.
    expect(find.text('Basmati rice'), findsOneWidget);
    expect(find.textContaining('Rice, white, basmati, boiled'), findsOneWidget);
    expect(find.text('Chicken tikka'), findsOneWidget);
    expect(find.text('Cooked in fat?'), findsOneWidget);

    final req = identifier.lastRequest!;
    expect(req.imageBase64, isNotEmpty);
    expect(req.localTime, matches(RegExp(r'^\d\d:\d\d$')));
    expect(req.toJson().keys, isNot(contains('grams')));

    final consent = await tester.runAsync(
      () => services.profiles.latestConsent(ConsentRecord.photoRecognition),
    );
    expect(consent!.granted, isTrue);

    await tester.tap(find.text('Basmati rice'));
    await settle(tester);
    expect(outcome!.picked!.id, 'cofid:rice-boiled');
    expect(outcome!.matched, hasLength(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('declining consent sends nothing', (tester) async {
    PhotoOutcome? outcome;
    await tester.pumpWidget(
      host(
        open: (context) => Center(
          child: FilledButton(
            onPressed: () async =>
                outcome = await PhotoIdentifySheet.show(context),
            child: const Text('Photo'),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Photo'));
    await settle(tester);
    await tester.tap(find.text('Not now, I will search'));
    await settle(tester);
    expect(outcome, isNull);
    expect(identifier.lastRequest, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a degraded reply is shown honestly and weighing goes on',
      (tester) async {
    identifier = FakeIdentifier(IdentifyResult.unavailable);
    await tester.runAsync(
      () => services.profiles.recordConsent(
        ConsentRecord(
          purpose: ConsentRecord.photoRecognition,
          policyVersion: ConsentRecord.currentPolicyVersion,
          granted: true,
          grantedAt: DateTime.now(),
        ),
      ),
    );
    await tester.pumpWidget(
      host(
        open: (context) => Center(
          child: FilledButton(
            onPressed: () => PhotoIdentifySheet.show(context),
            child: const Text('Photo'),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Photo'));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(find.text('Nothing recognised'), findsOneWidget);
    expect(find.textContaining('You can still'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
