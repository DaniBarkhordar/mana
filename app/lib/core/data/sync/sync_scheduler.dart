/// Decides when to sync: shortly after every local write, whenever the app
/// comes to the foreground, and once a minute while it is open. The engine
/// itself never blocks the UI; this just kicks it.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../db/database.dart';
import 'sync_engine.dart';

class SyncScheduler with WidgetsBindingObserver {
  SyncScheduler({
    required SyncEngine engine,
    required AppDatabase db,
    this.interval = const Duration(seconds: 60),
    this.debounce = const Duration(seconds: 3),
  })  : _engine = engine,
        _db = db;

  final SyncEngine _engine;
  final AppDatabase _db;
  final Duration interval;
  final Duration debounce;

  final _reports = StreamController<SyncReport>.broadcast();
  Timer? _timer;
  Timer? _debounceTimer;
  StreamSubscription<void>? _writes;
  bool _started = false;

  /// Every completed attempt, for a status line in Settings.
  Stream<SyncReport> get reports => _reports.stream;

  SyncReport? lastReport;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(interval, (_) => _kick(reason: 'timer'));
    _writes = _db.tableUpdates().listen((_) => _afterWrite());
    _kick(reason: 'start');
  }

  Future<void> stop() async {
    _timer?.cancel();
    _debounceTimer?.cancel();
    await _writes?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _kick(reason: 'resumed');
  }

  /// Sync now, for a pull-to-refresh or a "back up now" button.
  Future<SyncReport> syncNow() => _run();

  void _afterWrite() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () async {
      // The engine's own writes (marking rows synced, applying pulls) land
      // here too; they leave nothing pending, so this stays quiet.
      if (await _engine.hasPendingChanges()) await _run();
    });
  }

  void _kick({required String reason}) {
    unawaited(_run());
  }

  Future<SyncReport> _run() async {
    final report = await _engine.syncNow();
    if (report.outcome != SyncOutcome.busy) {
      lastReport = report;
      _reports.add(report);
    }
    return report;
  }
}
