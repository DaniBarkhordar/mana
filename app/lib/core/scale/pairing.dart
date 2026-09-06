/// Remembering which scale is the user's, and deciding which one holds the
/// radio.
///
/// Pairing is deliberately local to this phone: on iOS the identifier a scale
/// advertises under is a per-install CoreBluetooth UUID, so a pairing record
/// synced from another device could never be reconnected anyway. The record
/// lives in the local key-value table and dies with the install, which is the
/// honest lifetime for it.
library;

import 'dart:async';
import 'dart:convert';

import '../data/db/database.dart';
import 'scale_driver.dart';

/// A scale the user chose in the pairing sheet.
class PairedScale {
  const PairedScale({
    required this.id,
    required this.name,
    required this.kind,
    this.modelCode,
    this.protocolHint,
    this.pairedAt,
  });

  factory PairedScale.fromDiscovered(DiscoveredScale s, {DateTime? at}) =>
      PairedScale(
        id: s.id,
        name: s.name,
        kind: s.kind,
        modelCode: s.modelCode,
        protocolHint: s.protocolHint,
        pairedAt: at ?? DateTime.now(),
      );

  factory PairedScale.fromJson(Map<String, dynamic> json) => PairedScale(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Scale',
        kind: ScaleKind.values.byName(json['kind'] as String),
        modelCode: json['modelCode'] as String?,
        protocolHint: json['protocolHint'] as String?,
        pairedAt: json['pairedAt'] == null
            ? null
            : DateTime.parse(json['pairedAt'] as String),
      );

  final String id;
  final String name;
  final ScaleKind kind;
  final String? modelCode;
  final String? protocolHint;
  final DateTime? pairedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'modelCode': modelCode,
        'protocolHint': protocolHint,
        'pairedAt': pairedAt?.toIso8601String(),
      };

  DiscoveredScale toDiscovered() => DiscoveredScale(
        id: id,
        name: name,
        kind: kind,
        protocolHint: protocolHint,
        modelCode: modelCode,
      );
}

/// One pairing per kind, in the local key-value table.
class ScalePairingStore {
  ScalePairingStore(this._db);

  final AppDatabase _db;

  static String keyFor(ScaleKind kind) => 'paired_scale:${kind.name}';

  Future<PairedScale?> read(ScaleKind kind) async {
    final raw = await _db.stateValue(keyFor(kind));
    if (raw == null) return null;
    try {
      return PairedScale.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Stream<PairedScale?> watch(ScaleKind kind) {
    final query = _db.select(_db.syncState)
      ..where((s) => s.key.equals(keyFor(kind)));
    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      try {
        return PairedScale.fromJson(
          jsonDecode(row.value) as Map<String, dynamic>,
        );
      } on Object {
        return null;
      }
    });
  }

  Future<void> save(PairedScale scale) =>
      _db.setStateValue(keyFor(scale.kind), jsonEncode(scale.toJson()));

  Future<void> forget(ScaleKind kind) =>
      (_db.delete(_db.syncState)..where((s) => s.key.equals(keyFor(kind))))
          .go();
}

/// Hands the radio to whichever scale the user is looking at.
///
/// The vendor SDK holds one connection. The body scale is the default —
/// stepping on it is the daily habit — and the kitchen scale takes over while
/// the Weigh food screen is open. Drivers that are not [ScaleDriver.exclusive]
/// (the simulated one) are simply left connected.
class ScaleConnectionCoordinator {
  ScaleConnectionCoordinator({
    required this.body,
    required this.kitchen,
    required this.pairing,
    this.scanTimeout = const Duration(seconds: 20),
  });

  final ScaleDriver body;
  final ScaleDriver kitchen;
  final ScalePairingStore pairing;
  final Duration scanTimeout;

  ScaleKind _focus = ScaleKind.body;
  Future<void>? _inFlight;

  ScaleKind get focus => _focus;

  ScaleDriver driverFor(ScaleKind kind) =>
      kind == ScaleKind.body ? body : kitchen;

  /// Brings up every scale that has a pairing. On exclusive drivers only the
  /// focused one connects.
  Future<void> start() => focusOn(_focus, force: true);

  /// Give the radio to [kind]. Serialised so a fast tab switch cannot leave
  /// two connects racing the SDK.
  Future<void> focusOn(ScaleKind kind, {bool force = false}) async {
    if (!force && kind == _focus) return;
    _focus = kind;
    final previous = _inFlight;
    final work = () async {
      try {
        await previous;
      } on Object {
        // The previous hand-over failed; this one starts clean.
      }
      await _apply(kind);
    }();
    _inFlight = work;
    await work;
  }

  Future<void> _apply(ScaleKind kind) async {
    final other = kind == ScaleKind.body ? ScaleKind.kitchen : ScaleKind.body;
    final otherDriver = driverFor(other);
    if (otherDriver.exclusive || driverFor(kind).exclusive) {
      try {
        await otherDriver.disconnect();
      } on Object {
        // Not connected in the first place.
      }
    } else {
      // Nothing shares a radio: keep both up.
      await _connectPaired(other);
    }
    await _connectPaired(kind);
  }

  /// Scans until the remembered scale shows up, then connects. Without a
  /// pairing nothing happens — the pairing sheet is the only place a scale
  /// is chosen, so a stranger's scale on the same floor is never picked up.
  Future<bool> _connectPaired(ScaleKind kind) async {
    final driver = driverFor(kind);
    try {
      if (!await driver.initialise()) return false;
      final paired = await pairing.read(kind);
      if (paired == null) return false;
      final found = await driver
          .scan(timeout: scanTimeout)
          .firstWhere((s) => s.id == paired.id);
      await driver.stopScan();
      await driver.connect(found);
      return true;
    } on Object {
      // Out of range, switched off, or Bluetooth is off. The readout says
      // "Looking for your scale"; nothing else depends on it.
      return false;
    }
  }

  /// Pair [scale] as the user's [kind] scale and connect it now.
  Future<void> pair(DiscoveredScale scale) async {
    await pairing.save(PairedScale.fromDiscovered(scale));
    final driver = driverFor(scale.kind);
    if (driver.exclusive) {
      final other =
          scale.kind == ScaleKind.body ? ScaleKind.kitchen : ScaleKind.body;
      try {
        await driverFor(other).disconnect();
      } on Object {
        // Not connected.
      }
    }
    _focus = scale.kind;
    await driver.stopScan();
    await driver.connect(scale);
  }

  Future<void> forget(ScaleKind kind) async {
    await pairing.forget(kind);
    try {
      await driverFor(kind).disconnect();
    } on Object {
      // Not connected.
    }
  }
}
