import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/notifications/reminders.dart';
import 'package:mananu/core/notifications/reminders_providers.dart';
import 'package:mananu/features/settings/reminders_section.dart';
import 'package:mananu/features/settings/settings_screen.dart';
import 'package:mananu/theme/tokens.dart';

class _FakeScheduler implements NotificationScheduler {
  _FakeScheduler({this.grant = true});

  final bool grant;
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  late AppServices services;
  late _FakeScheduler scheduler;

  setUp(() {
    services = AppServices.inMemory();
    scheduler = _FakeScheduler();
  });
  tearDown(() => services.db.close());

  Widget app() => ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: MaterialApp(
          theme: MananuTheme.light(),
          home: const SettingsScreen(),
        ),
      );

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Drift completes on real async, so a read from the table has to leave
  /// the widget test's fake clock.
  Future<String?> stored(WidgetTester tester, String key) =>
      tester.runAsync(() => services.db.stateValue(key)).then((v) => v);

  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> scrollToReminders(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(RemindersSection.masterSwitchKey),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
  }

  testWidgets('renders after Your data, before About, all off', (tester) async {
    await pumpSettings(tester);
    await scrollToReminders(tester);

    expect(find.text('REMINDERS'), findsOneWidget);
    expect(find.text('Morning weigh-in'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Off'), findsNWidgets(4));
    expect(
      find.text('Off. Nothing is sent until you switch this on.'),
      findsOneWidget,
    );

    final master = tester.widget<SwitchListTile>(
      find.byKey(RemindersSection.masterSwitchKey),
    );
    expect(master.value, isFalse);

    // Section order: Your data, Reminders, About. Read from the list's
    // children rather than the screen, since the list builds lazily and a
    // section scrolled away is no longer in the tree.
    final list = tester.widget<ListView>(find.byType(ListView));
    final children =
        (list.childrenDelegate as SliverChildListDelegate).children;
    int sectionIndex(String title) => children.indexWhere(
          (w) => w is MananuSection && w.title == title,
        );
    final yourData = sectionIndex('Your data');
    final reminders = children.indexWhere((w) => w is RemindersSection);
    final about = sectionIndex('About');
    expect(yourData, greaterThanOrEqualTo(0));
    expect(reminders, greaterThan(yourData));
    expect(about, greaterThan(reminders));
    // Immediately after, allowing for the spacer between sections.
    expect(reminders - yourData, 2);
    expect(about - reminders, 2);

    // Nothing asked for while the switch is off.
    expect(scheduler.permissionRequests, 0);
    await shutDown(tester);
  });

  testWidgets('the master switch asks once and persists', (tester) async {
    await pumpSettings(tester);
    await scrollToReminders(tester);

    await tester.tap(find.byKey(RemindersSection.masterSwitchKey));
    await settle(tester);

    expect(scheduler.permissionRequests, 1);
    expect(await stored(tester, ReminderSettings.enabledKey), 'true');
    final master = tester.widget<SwitchListTile>(
      find.byKey(RemindersSection.masterSwitchKey),
    );
    expect(master.value, isTrue);
    expect(
      find.text('On. Choose a time below for each reminder you want.'),
      findsOneWidget,
    );

    // Off again: no second prompt, and the table says so.
    await tester.tap(find.byKey(RemindersSection.masterSwitchKey));
    await settle(tester);
    expect(scheduler.permissionRequests, 1);
    expect(await stored(tester, ReminderSettings.enabledKey), 'false');
    await shutDown(tester);
  });

  testWidgets('a refused permission leaves the switch off', (tester) async {
    scheduler = _FakeScheduler(grant: false);
    await pumpSettings(tester);
    await scrollToReminders(tester);

    await tester.tap(find.byKey(RemindersSection.masterSwitchKey));
    await settle(tester);

    expect(scheduler.permissionRequests, 1);
    expect(await stored(tester, ReminderSettings.enabledKey), isNull);
    expect(
      find.textContaining('Notifications are off for Mananu'),
      findsOneWidget,
    );
    await shutDown(tester);
  });

  testWidgets('a time row opens the picker and stores the choice',
      (tester) async {
    await pumpSettings(tester);
    await scrollToReminders(tester);

    await tester.tap(find.text('Lunch'));
    await settle(tester);
    expect(find.text('LUNCH'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await settle(tester);

    // The picker opened on the suggested 13:00 and OK kept it.
    expect(await stored(tester, ReminderSettings.lunchKey), '13:00');
    expect(find.text('Off'), findsNWidgets(3));

    // The cross beside the time turns that one reminder off again.
    await tester.tap(find.byTooltip('Turn off'));
    await settle(tester);
    expect(await stored(tester, ReminderSettings.lunchKey), '');
    expect(find.text('Off'), findsNWidgets(4));
    await shutDown(tester);
  });
}
