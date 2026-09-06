/// Mananu Plus.
///
/// Free forever: weighing, barcodes, manual logging, targets, body trends.
/// Plus (£4.99 a month or £39.99 a year): photo recognition beyond thirty
/// scans a month, recipes, personal calibration.
///
/// The store and RevenueCat decide who has Plus. The app only *shows* it:
/// the server reads `public.entitlements`, which the RevenueCat webhook
/// keeps in step, and never trusts the client (HANDOFF Phase 4 item 6).
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat public SDK keys, one per store, injected at build time:
///
/// ```
/// --dart-define=REVENUECAT_IOS_KEY=appl_... --dart-define=REVENUECAT_ANDROID_KEY=goog_...
/// ```
///
/// Public keys, not secrets; the webhook secret lives on the server only.
class BillingConfig {
  const BillingConfig._();

  static const iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

  /// The entitlement identifier configured in RevenueCat.
  static const entitlementId = 'plus';

  static String get keyForPlatform => Platform.isIOS || Platform.isMacOS
      ? iosKey
      : Platform.isAndroid
          ? androidKey
          : '';

  static bool get isConfigured => keyForPlatform.isNotEmpty;
}

class PlusStatus {
  const PlusStatus({
    required this.isPlus,
    this.willRenew = false,
    this.expiresAt,
    this.productId,
  });

  static const free = PlusStatus(isPlus: false);

  final bool isPlus;
  final bool willRenew;
  final DateTime? expiresAt;
  final String? productId;
}

/// One thing that can be bought.
class PlusOffer {
  const PlusOffer({
    required this.id,
    required this.title,
    required this.priceString,
    required this.period,
  });

  final String id;
  final String title;

  /// Localised, from the store: "£4.99".
  final String priceString;
  final PlusPeriod period;
}

enum PlusPeriod { monthly, annual, other }

/// Thrown when the person dismissed the store sheet. Not an error to show.
class PurchaseCancelled implements Exception {
  const PurchaseCancelled();
}

/// What the entitlement service needs, so the logic is testable without the
/// store.
abstract class BillingBackend {
  Future<void> configure({required String apiKey, String? appUserId});
  Future<void> identify(String appUserId);
  Future<PlusStatus> currentStatus();
  Stream<PlusStatus> get statusChanges;
  Future<List<PlusOffer>> offers();
  Future<PlusStatus> purchase(String offerId);
  Future<PlusStatus> restore();
}

class EntitlementService {
  EntitlementService(this._backend, {this.enabled = true});

  final BillingBackend _backend;

  /// False in a build without RevenueCat keys: everything reads as free
  /// and the paywall explains itself.
  final bool enabled;

  bool _configured = false;
  String? _identifiedAs;
  final _status = StreamController<PlusStatus>.broadcast();
  PlusStatus _last = PlusStatus.free;
  StreamSubscription<PlusStatus>? _sub;

  PlusStatus get status => _last;
  Stream<PlusStatus> get changes => _status.stream;

  Future<void> ensureConfigured({String? appUserId}) async {
    if (!enabled) return;
    if (!_configured) {
      await _backend.configure(
        apiKey: BillingConfig.keyForPlatform,
        appUserId: appUserId,
      );
      _configured = true;
      _identifiedAs = appUserId;
      _sub = _backend.statusChanges.listen(_emit);
      _emit(await _backend.currentStatus());
    }
  }

  /// Ties purchases to the account, so Plus follows a sign-in to a new
  /// phone and the webhook can name the user. Called whenever the account
  /// changes; a no-op when nothing changed.
  Future<void> identify(String appUserId) async {
    if (!enabled) return;
    await ensureConfigured(appUserId: appUserId);
    if (_identifiedAs == appUserId) return;
    await _backend.identify(appUserId);
    _identifiedAs = appUserId;
    _emit(await _backend.currentStatus());
  }

  Future<List<PlusOffer>> offers() async {
    if (!enabled) return const [];
    await ensureConfigured();
    final all = await _backend.offers();
    // Annual first: it is the better deal and the one to make the case for.
    all.sort((a, b) => a.period.index.compareTo(b.period.index) * -1);
    return all;
  }

  Future<PlusStatus> purchase(PlusOffer offer) async {
    await ensureConfigured();
    final status = await _backend.purchase(offer.id);
    _emit(status);
    return status;
  }

  Future<PlusStatus> restore() async {
    await ensureConfigured();
    final status = await _backend.restore();
    _emit(status);
    return status;
  }

  void _emit(PlusStatus s) {
    _last = s;
    if (!_status.isClosed) _status.add(s);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _status.close();
  }
}

/// The real store.
class RevenueCatBackend implements BillingBackend {
  RevenueCatBackend();

  final _changes = StreamController<PlusStatus>.broadcast();
  bool _listening = false;

  @override
  Future<void> configure({required String apiKey, String? appUserId}) async {
    final config = PurchasesConfiguration(apiKey)..appUserID = appUserId;
    await Purchases.configure(config);
    if (!_listening) {
      _listening = true;
      Purchases.addCustomerInfoUpdateListener(
        (info) => _changes.add(statusOf(info)),
      );
    }
  }

  @override
  Future<void> identify(String appUserId) async {
    await Purchases.logIn(appUserId);
  }

  @override
  Future<PlusStatus> currentStatus() async =>
      statusOf(await Purchases.getCustomerInfo());

  @override
  Stream<PlusStatus> get statusChanges => _changes.stream;

  @override
  Future<List<PlusOffer>> offers() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return const [];
    return [
      for (final p in current.availablePackages)
        PlusOffer(
          id: p.identifier,
          title: p.storeProduct.title,
          priceString: p.storeProduct.priceString,
          period: switch (p.packageType) {
            PackageType.monthly => PlusPeriod.monthly,
            PackageType.annual => PlusPeriod.annual,
            _ => PlusPeriod.other,
          },
        ),
    ];
  }

  @override
  Future<PlusStatus> purchase(String offerId) async {
    final offerings = await Purchases.getOfferings();
    final package = offerings.current?.availablePackages
        .where((p) => p.identifier == offerId)
        .firstOrNull;
    if (package == null) throw StateError('offer $offerId is not on sale');
    try {
      return statusOf(await Purchases.purchasePackage(package));
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelled();
      }
      rethrow;
    }
  }

  @override
  Future<PlusStatus> restore() async =>
      statusOf(await Purchases.restorePurchases());

  /// Pure: the entitlement we sell, out of everything RevenueCat knows.
  static PlusStatus statusOf(CustomerInfo info) {
    final e = info.entitlements.active[BillingConfig.entitlementId];
    if (e == null || !e.isActive) return PlusStatus.free;
    return PlusStatus(
      isPlus: true,
      willRenew: e.willRenew,
      expiresAt: e.expirationDate == null
          ? null
          : DateTime.tryParse(e.expirationDate!),
      productId: e.productIdentifier,
    );
  }
}

/// A build without keys.
class NoBillingBackend implements BillingBackend {
  const NoBillingBackend();

  @override
  Future<void> configure({required String apiKey, String? appUserId}) async {}

  @override
  Future<void> identify(String appUserId) async {}

  @override
  Future<PlusStatus> currentStatus() async => PlusStatus.free;

  @override
  Stream<PlusStatus> get statusChanges => const Stream.empty();

  @override
  Future<List<PlusOffer>> offers() async => const [];

  @override
  Future<PlusStatus> purchase(String offerId) =>
      throw StateError('billing is not configured in this build');

  @override
  Future<PlusStatus> restore() async => PlusStatus.free;
}
