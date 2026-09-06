import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../theme/tokens.dart';

/// Connected sources.
///
/// Every value from a wearable arrives as an observation with its source
/// named, so this screen is the honest ledger of who said what. Direct
/// integrations (Oura, WHOOP, Garmin) come through the same door; until each
/// is live the row says so rather than pretending.
class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final importer = await ref.read(healthImporterProvider.future);
      final ok = await importer.connect(writeWeight: false);
      setState(
        () => _message = ok
            ? 'Connected. The last thirty days are in.'
            : 'Access was not granted. You can allow it in the Health app '
                'and try again.',
      );
    } on Object {
      setState(
        () => _message = 'Health is not available on this device.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importNow() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final importer = await ref.read(healthImporterProvider.future);
      final n = await importer.importSince();
      setState(
        () => _message = n == 0
            ? 'Nothing new since the last import.'
            : '$n new ${n == 1 ? 'value' : 'values'} imported.',
      );
    } on Object {
      setState(() => _message = 'Could not read from Health just now.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final connected = ref.watch(healthConnectedProvider).valueOrNull ?? false;
    final writes = ref.watch(healthWritesWeightProvider).valueOrNull ?? false;
    final lastImport = ref.watch(healthLastImportProvider).valueOrNull;
    final sources =
        ref.watch(observationSourcesProvider).valueOrNull ?? const [];
    final importer = ref.watch(healthImporterProvider).valueOrNull;
    final storeName = importer?.gateway.displayName ?? 'Health';

    return Scaffold(
      appBar: AppBar(title: const Text('Connected sources')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.lg,
          MananuSpacing.sm,
          MananuSpacing.lg,
          MananuSpacing.huge,
        ),
        children: [
          Text(
            'Sleep, resting heart rate, HRV, steps and workouts from the '
            'devices you already wear, next to your scale readings on one '
            'timeline. Each value keeps the name of the device that made it.',
            style: MananuType.body.copyWith(color: muted),
          ),
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: storeName,
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: MananuSpacing.lg,
                      vertical: MananuSpacing.sm,
                    ),
                    leading: Icon(
                      Icons.favorite_outline,
                      color:
                          connected ? MananuColors.measured : scheme.onSurface,
                    ),
                    title: Text(
                      connected ? 'Connected' : 'Not connected',
                      style: MananuType.bodyStrong,
                    ),
                    subtitle: Text(
                      connected
                          ? lastImport == null
                              ? 'Reads sleep, heart, steps and workouts.'
                              : 'Last import ${DateFormat('d MMM, HH:mm').format(lastImport.toLocal())}.'
                          : 'Reads sleep, resting heart rate, HRV, steps and '
                              'workouts. Nothing is written unless you say so '
                              'below.',
                      style: MananuType.caption,
                    ),
                    trailing: connected
                        ? TextButton(
                            onPressed: _busy ? null : _importNow,
                            child: const Text('Import now'),
                          )
                        : null,
                  ),
                  if (!connected)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MananuSpacing.lg,
                        0,
                        MananuSpacing.lg,
                        MananuSpacing.lg,
                      ),
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _connect,
                        icon: const Icon(Icons.favorite_outline),
                        label: Text(
                          storeName == 'Apple Health'
                              ? 'Connect Apple Health'
                              : 'Connect',
                        ),
                      ),
                    ),
                  if (connected) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: MananuSpacing.lg,
                        vertical: MananuSpacing.sm,
                      ),
                      secondary: Icon(
                        Icons.monitor_weight_outlined,
                        color: scheme.onSurface,
                      ),
                      title: const Text(
                        'Share weight with Health',
                        style: MananuType.bodyStrong,
                      ),
                      subtitle: const Text(
                        'Each scale reading, as measured. Body fat is worked '
                        'out, not measured, so it stays here.',
                        style: MananuType.caption,
                      ),
                      value: writes,
                      onChanged: _busy
                          ? null
                          : (v) async {
                              final imp =
                                  await ref.read(healthImporterProvider.future);
                              await imp.setWriteWeight(v);
                            },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: MananuSpacing.lg,
                        vertical: MananuSpacing.sm,
                      ),
                      leading: Icon(Icons.link_off, color: scheme.onSurface),
                      title: const Text(
                        'Disconnect',
                        style: MananuType.bodyStrong,
                      ),
                      subtitle: const Text(
                        'Stops reading. What was imported stays in your diary '
                        'until you delete it.',
                        style: MananuType.caption,
                      ),
                      onTap: _busy
                          ? null
                          : () async {
                              final imp =
                                  await ref.read(healthImporterProvider.future);
                              await imp.disconnect();
                            },
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: MananuSpacing.md),
            Text(_message!, style: MananuType.caption.copyWith(color: muted)),
          ],
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: 'Direct connections',
            child: Card(
              child: Column(
                children: [
                  for (final (i, name) in const [
                    'Oura',
                    'WHOOP',
                    'Garmin',
                    'Fitbit',
                    'Polar',
                    'Withings',
                  ].indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: MananuSpacing.lg,
                        vertical: MananuSpacing.xs,
                      ),
                      title: Text(name, style: MananuType.bodyStrong),
                      subtitle: Text(
                        'Not yet. Until then, $name writes to $storeName and '
                        'arrives from there.',
                        style: MananuType.caption,
                      ),
                      trailing: Text(
                        'Soon',
                        style: MananuType.caption.copyWith(color: muted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: 'In your diary',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(MananuSpacing.lg),
                child: sources.isEmpty
                    ? Text(
                        'No sources yet.',
                        style: MananuType.caption.copyWith(color: muted),
                      )
                    : Wrap(
                        spacing: MananuSpacing.sm,
                        runSpacing: MananuSpacing.sm,
                        children: [
                          for (final s in sources)
                            Chip(
                              label: Text(sourceLabel(s)),
                              labelStyle: MananuType.caption,
                              side: BorderSide(color: scheme.outline),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          Text(
            'Health data never reaches an analytics or advertising service, '
            'and is never used for anything like insurance or employment. '
            'That is in the privacy policy, and it is in the code.',
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  /// "apple_health" → "Apple Health", "mananu_body_scale" → "Mananu body scale".
  static String sourceLabel(String source) => switch (source) {
        'apple_health' => 'Apple Health',
        'health_connect' => 'Health Connect',
        'simulated_scale' => 'Demo scale',
        'mananu_body_scale' => 'Mananu body scale',
        'mananu_kitchen_scale' => 'Mananu kitchen scale',
        _ => source.replaceAll('_', ' '),
      };
}
