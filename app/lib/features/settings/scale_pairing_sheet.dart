import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/scale/scale_driver.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';

/// Choosing which scale is yours.
///
/// The only place a scale is ever picked. Auto-connect never grabs the first
/// scale it sees — a flat above a gym has a dozen — so the user chooses once
/// and the app remembers on this phone.
class ScalePairingSheet extends ConsumerStatefulWidget {
  const ScalePairingSheet({super.key, required this.kind});

  final ScaleKind kind;

  static Future<void> show(BuildContext context, ScaleKind kind) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => ScalePairingSheet(kind: kind),
      );

  @override
  ConsumerState<ScalePairingSheet> createState() => _ScalePairingSheetState();
}

class _ScalePairingSheetState extends ConsumerState<ScalePairingSheet> {
  final Map<String, DiscoveredScale> _found = {};
  StreamSubscription<DiscoveredScale>? _scan;
  bool _scanning = false;
  bool _unauthorised = false;
  String? _connectingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    unawaited(_scan?.cancel());
    super.dispose();
  }

  ScaleDriver get _driver => widget.kind == ScaleKind.body
      ? ref.read(bodyScaleDriverProvider)
      : ref.read(kitchenScaleDriverProvider);

  Future<void> _startScan() async {
    await _scan?.cancel();
    setState(() {
      _found.clear();
      _scanning = true;
      _error = null;
    });
    final driver = _driver;
    if (!await driver.initialise()) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _unauthorised = true;
        });
      }
      return;
    }
    _scan = driver.scan(timeout: const Duration(seconds: 30)).listen(
      (s) => setState(() => _found[s.id] = s),
      onDone: () {
        if (mounted) setState(() => _scanning = false);
      },
      onError: (Object e) {
        if (mounted) {
          setState(() {
            _scanning = false;
            _error = 'Could not scan. Is Bluetooth on?';
          });
        }
      },
    );
  }

  Future<void> _pair(DiscoveredScale scale) async {
    await _scan?.cancel();
    setState(() {
      _scanning = false;
      _connectingId = scale.id;
      _error = null;
    });
    try {
      final coordinator = await ref.read(scaleCoordinatorProvider.future);
      await coordinator.pair(scale);
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() {
          _connectingId = null;
          _error = 'Could not connect to ${scale.name}. Step on it or put '
              'something on it to wake it, then try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final isBody = widget.kind == ScaleKind.body;
    final scales = _found.values.toList()
      ..sort((a, b) => (b.rssi ?? -100).compareTo(a.rssi ?? -100));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.xl,
          MananuSpacing.sm,
          MananuSpacing.xl,
          MananuSpacing.xl,
        ),
        children: [
          Text(
            isBody ? 'Pair your body scale' : 'Pair your kitchen scale',
            style: MananuType.title,
          ),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            isBody
                ? 'Step on the scale so it wakes up, then choose it below.'
                : 'Put something on the scale so it wakes up, then choose it '
                    'below.',
            style: MananuType.body.copyWith(color: muted),
          ),
          const SizedBox(height: MananuSpacing.lg),
          if (_unauthorised)
            const _Notice(
              text: 'The scale software could not start on this build. '
                  'Weight logging still works; get in touch and we will sort '
                  'it.',
              colour: MananuColors.danger,
            )
          else if (_error != null)
            _Notice(text: _error!, colour: MananuColors.warning),
          if (scales.isEmpty && _scanning)
            const _Searching()
          else if (scales.isEmpty)
            _Nothing(onRetry: _startScan)
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < scales.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _ScaleTile(
                      scale: scales[i],
                      connecting: _connectingId == scales[i].id,
                      enabled: _connectingId == null,
                      onTap: () => _pair(scales[i]),
                    ),
                  ],
                ],
              ),
            ),
          if (scales.isNotEmpty && _scanning) ...[
            const SizedBox(height: MananuSpacing.md),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: MananuSpacing.sm),
                Text(
                  'Still looking…',
                  style: MananuType.caption.copyWith(color: muted),
                ),
              ],
            ),
          ],
          if (scales.isNotEmpty && !_scanning && _connectingId == null) ...[
            const SizedBox(height: MananuSpacing.md),
            TextButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Scan again'),
            ),
          ],
          const SizedBox(height: MananuSpacing.lg),
          Text(
            'Mananu only ever connects to the scale you choose here. '
            'Readings from anyone else\'s scale are never picked up.',
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleTile extends StatelessWidget {
  const _ScaleTile({
    required this.scale,
    required this.connecting,
    required this.enabled,
    required this.onTap,
  });

  final DiscoveredScale scale;
  final bool connecting;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = [
      if (scale.modelCode != null && scale.modelCode!.isNotEmpty)
        scale.modelCode!,
      if (scale.rssi != null) _signal(scale.rssi!),
    ].join(' · ');
    return ListTile(
      enabled: enabled,
      onTap: onTap,
      leading: Icon(
        scale.kind == ScaleKind.body
            ? Icons.monitor_weight_outlined
            : Icons.scale_outlined,
        color: scheme.onSurface,
      ),
      title: Text(scale.name, style: MananuType.bodyStrong),
      subtitle: detail.isEmpty ? null : Text(detail, style: MananuType.caption),
      trailing: connecting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.chevron_right,
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
    );
  }

  static String _signal(int rssi) {
    if (rssi >= -60) return 'Right here';
    if (rssi >= -75) return 'Nearby';
    return 'Weak signal';
  }
}

class _Searching extends StatelessWidget {
  const _Searching();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MananuSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: MananuSpacing.lg),
          Text(
            'Looking for scales…',
            style: MananuType.body.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Nothing extends StatelessWidget {
  const _Nothing({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MananuSpacing.xl),
      child: Column(
        children: [
          const MananuMark(height: 24),
          const SizedBox(height: MananuSpacing.lg),
          const Text('No scale found', style: MananuType.heading),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            'Wake the scale, make sure Bluetooth is on, and try again. Scales '
            'sleep after a minute of stillness.',
            textAlign: TextAlign.center,
            style: MananuType.body.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: MananuSpacing.lg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan again'),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.colour});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MananuSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(MananuSpacing.md),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.1),
          borderRadius: MananuSpacing.radiusSm,
        ),
        child: Text(text, style: MananuType.caption.copyWith(color: colour)),
      ),
    );
  }
}
