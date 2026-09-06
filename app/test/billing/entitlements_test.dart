import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/billing/entitlements.dart';

class FakeBilling implements BillingBackend {
  FakeBilling({this.status = PlusStatus.free, this.available = const []});

  PlusStatus status;
  List<PlusOffer> available;
  final calls = <String>[];
  final _changes = StreamController<PlusStatus>.broadcast();

  void push(PlusStatus s) {
    status = s;
    _changes.add(s);
  }

  @override
  Future<void> configure({required String apiKey, String? appUserId}) async =>
      calls.add('configure user=$appUserId');

  @override
  Future<void> identify(String appUserId) async =>
      calls.add('identify $appUserId');

  @override
  Future<PlusStatus> currentStatus() async => status;

  @override
  Stream<PlusStatus> get statusChanges => _changes.stream;

  @override
  Future<List<PlusOffer>> offers() async => available;

  @override
  Future<PlusStatus> purchase(String offerId) async {
    calls.add('purchase $offerId');
    return status = const PlusStatus(isPlus: true, willRenew: true);
  }

  @override
  Future<PlusStatus> restore() async {
    calls.add('restore');
    return status;
  }
}

const _monthly = PlusOffer(
  id: 'monthly',
  title: 'Mananu Plus Monthly',
  priceString: '£4.99',
  period: PlusPeriod.monthly,
);
const _annual = PlusOffer(
  id: 'annual',
  title: 'Mananu Plus Yearly',
  priceString: '£39.99',
  period: PlusPeriod.annual,
);

void main() {
  test('configures once, identifies the account, and follows the store',
      () async {
    final billing = FakeBilling();
    final service = EntitlementService(billing);
    final seen = <bool>[];
    service.changes.listen((s) => seen.add(s.isPlus));

    await service.identify('user-1');
    await service.identify('user-1');
    expect(billing.calls, ['configure user=user-1']);
    expect(service.status.isPlus, isFalse);

    billing.push(const PlusStatus(isPlus: true));
    await Future<void>.delayed(Duration.zero);
    expect(service.status.isPlus, isTrue);

    await service.identify('user-2');
    expect(billing.calls.last, 'identify user-2');
    // Broadcast delivery is asynchronous.
    await Future<void>.delayed(Duration.zero);
    expect(seen, [false, true, true]);
    await service.dispose();
  });

  test('offers are annual first and a purchase flips the status', () async {
    final billing = FakeBilling(available: [_monthly, _annual]);
    final service = EntitlementService(billing);
    final offers = await service.offers();
    expect(offers.map((o) => o.id), ['annual', 'monthly']);
    final after = await service.purchase(offers.last);
    expect(after.isPlus, isTrue);
    expect(service.status.isPlus, isTrue);
    expect(billing.calls, contains('purchase monthly'));
    await service.dispose();
  });

  test('a build without keys reads as free and sells nothing', () async {
    final service =
        EntitlementService(const NoBillingBackend(), enabled: false);
    expect(service.status.isPlus, isFalse);
    expect(await service.offers(), isEmpty);
    await service.dispose();
  });
}
