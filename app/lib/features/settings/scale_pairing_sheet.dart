import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import '../../core/data/providers.dart';
import '../../core/scale/scale_driver.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';

/// Choosing which scale is yours.
///
/// The only place a scale is ever picked. Auto-connect never grabs the first
/// scale it sees — a flat above a gym has a dozen — so the user chooses once
/// and the app remembers on this phone.
///
/// Two steps. First, before any radio is touched, a plain statement of what
/// the operating system is about to ask for and why; a permission prompt
/// that arrives unexplained is the one most often refused, and a refused
/// Bluetooth permission is a scale that never pairs. Then the scan, led by
/// the one thing the user has to do: wake the scale.
class ScalePairingSheet extends ConsumerStatefulWidget {
  const ScalePairingSheet({super.key, required this.kind});

  final ScaleKind kind;

  /// How long one scan runs. Scales sleep after a minute of stillness and
  /// wake on a step, so a minute gives the user time to read the
  /// instruction, walk to the scale and step on it without the scan having
  /// already given up.
  static const scanWindow = Duration(seconds: 60);

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

enum _Step { permission, scanning }

class _ScalePairingSheetState extends ConsumerState<ScalePairingSheet> {
  final Map<String, DiscoveredScale> _found = {};
  StreamSubscription<DiscoveredScale>? _scan;
  _Step _step = _Step.permission;
  bool _scanning = false;
  bool _unauthorised = false;
  bool _forgetting = false;
  String? _connectingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The demo scale has no radio, so there is nothing for the operating
    // system to ask about: straight to the scan.
    if (_driver is SimulatedScaleDriver) {
      _step = _Step.scanning;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
    }
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
      _step = _Step.scanning;
      _found.clear();
      _scanning = true;
      _unauthorised = false;
      _error = null;
    });
    final driver = _driver;
    if (!await driver.initialise()) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _unauthorised = true;
          // Back to the explainer, now with a way into Settings.
          _step = _Step.permission;
        });
      }
      return;
    }
    _scan = driver.scan(timeout: ScalePairingSheet.scanWindow).listen(
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

  /// Clears the pairing through the coordinator — which also drops the
  /// link — and starts afresh, so a scale that was replaced or re-flashed
  /// can be chosen again without a trip through Settings.
  Future<void> _forgetAndRepair() async {
    await _scan?.cancel();
    setState(() {
      _forgetting = true;
      _scanning = false;
      _found.clear();
    });
    try {
      final coordinator = await ref.read(scaleCoordinatorProvider.future);
      await coordinator.forget(widget.kind);
    } finally {
      if (mounted) setState(() => _forgetting = false);
    }
    if (!mounted) return;
    if (_step == _Step.scanning) await _startScan();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final isBody = widget.kind == ScaleKind.body;
    final paired = ref.watch(pairedScaleProvider(widget.kind)).valueOrNull;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
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
          const SizedBox(height: MananuSpacing.lg),
          if (_step == _Step.permission)
            _PermissionStep(
              refused: _unauthorised,
              onContinue: _startScan,
            )
          else
            ..._scanningStep(context, muted),
          if (paired != null) ...[
            const SizedBox(height: MananuSpacing.lg),
            TextButton.icon(
              onPressed: _forgetting || _connectingId != null
                  ? null
                  : _forgetAndRepair,
              icon: const Icon(Icons.link_off, size: 18),
              label: Text('Forget ${paired.name} and re-pair'),
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

  List<Widget> _scanningStep(BuildContext context, Color muted) {
    final scales = _found.values.toList()
      ..sort((a, b) => (b.rssi ?? -100).compareTo(a.rssi ?? -100));
    // The strongest signal is, near enough, the scale in this room.
    final nearestId =
        scales.isNotEmpty && scales.first.rssi != null ? scales.first.id : null;

    return [
      _WakeHero(kind: widget.kind, active: _scanning),
      const SizedBox(height: MananuSpacing.lg),
      if (_error != null) _Notice(text: _error!, colour: MananuColors.warning),
      if (scales.isEmpty && _scanning)
        _Searching(muted: muted)
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
                  nearest: scales[i].id == nearestId,
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
    ];
  }
}

/// What the operating system is about to ask for, in the words it will use.
///
/// Platform by `defaultTargetPlatform`: it is what the app has at hand
/// without a device-info plugin, and it is overridable in tests. Android's
/// wording changed at 12 (API 31) — Nearby devices — and the SDK level is
/// not known here, so both sentences are shown to every Android user; the
/// one that applies is the one their phone will echo a moment later.
class _PermissionStep extends StatelessWidget {
  const _PermissionStep({required this.refused, required this.onContinue});

  /// The last attempt could not start scanning: the permission was refused,
  /// or the scale software would not initialise.
  final bool refused;
  final VoidCallback onContinue;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  String get _title => _isAndroid
      ? 'Your phone will ask for Nearby devices'
      : 'Your phone will ask for Bluetooth';

  String get _body => _isAndroid
      ? 'On Android 12 and later it is called Nearby devices. On Android 11 '
          'and earlier it is called Location, because Android calls '
          'Bluetooth scanning a location permission. Mananu never reads or '
          'stores your location.'
      : 'Mananu uses Bluetooth only to find and talk to your scale. Nothing '
          'about other devices nearby is kept.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          _isAndroid ? Icons.devices_other_outlined : Icons.bluetooth,
          size: 32,
          color: MananuColors.brass,
        ),
        const SizedBox(height: MananuSpacing.md),
        Text(_title, style: MananuType.heading),
        const SizedBox(height: MananuSpacing.sm),
        Text(_body, style: MananuType.body.copyWith(color: muted)),
        const SizedBox(height: MananuSpacing.lg),
        if (refused) ...[
          const _Notice(
            text: 'Mananu could not start scanning. If your phone refused the '
                'permission, allow it in Settings and try again. If it did '
                'not ask, the scale software could not start on this build: '
                'weight logging still works, and we will sort it if you get '
                'in touch.',
            colour: MananuColors.warning,
          ),
        ],
        FilledButton(onPressed: onContinue, child: const Text('Continue')),
        if (refused) ...[
          const SizedBox(height: MananuSpacing.sm),
          // permission_handler is already a dependency (the camera uses it),
          // and its openAppSettings lands on this app's own settings page on
          // both platforms; url_launcher can only open the top level of
          // Settings on iOS, and app_settings would be a package for one
          // call.
          OutlinedButton(
            onPressed: () => unawaited(openAppSettings()),
            child: const Text('Open Settings'),
          ),
        ],
      ],
    );
  }
}

/// The one thing the user has to do, made the centre of the step, with a
/// small, quiet motion so it reads as "do this now" rather than a caption.
class _WakeHero extends StatelessWidget {
  const _WakeHero({required this.kind, required this.active});

  final ScaleKind kind;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBody = kind == ScaleKind.body;
    return Column(
      children: [
        _StepOnAnimation(kind: kind, active: active),
        const SizedBox(height: MananuSpacing.lg),
        Text(
          isBody ? 'Step on the scale, then step off' : 'Switch the scale on',
          textAlign: TextAlign.center,
          style: MananuType.title,
        ),
        const SizedBox(height: MananuSpacing.xs),
        Text(
          isBody
              ? 'That wakes it. It appears below within a few seconds.'
              : 'It appears below within a few seconds of waking.',
          textAlign: TextAlign.center,
          style: MananuType.body.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// The mark settling onto a platform and lifting off again, on a slow loop.
/// Implicit animations only, so it costs one rebuild every couple of
/// seconds and nothing when the sheet is off screen. The kitchen scale has
/// no step to show, so its platform simply breathes.
class _StepOnAnimation extends StatefulWidget {
  const _StepOnAnimation({required this.kind, required this.active});

  final ScaleKind kind;
  final bool active;

  @override
  State<_StepOnAnimation> createState() => _StepOnAnimationState();
}

class _StepOnAnimationState extends State<_StepOnAnimation> {
  static const _beat = Duration(milliseconds: 1400);
  static const _move = Duration(milliseconds: 650);
  Timer? _timer;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_StepOnAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!widget.active) {
      _down = false;
      return;
    }
    _timer = Timer.periodic(_beat, (_) {
      if (mounted) setState(() => _down = !_down);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBody = widget.kind == ScaleKind.body;
    final platformColour = scheme.onSurface.withValues(alpha: 0.14);
    return SizedBox(
      height: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedPadding(
            duration: _move,
            curve: Curves.easeInOut,
            padding: EdgeInsets.only(
              bottom: isBody ? (_down ? 6 : 18) : 12,
            ),
            child: AnimatedOpacity(
              duration: _move,
              curve: Curves.easeInOut,
              opacity: isBody || !_down ? 1 : 0.45,
              child: const MananuMark(height: 22),
            ),
          ),
          AnimatedContainer(
            duration: _move,
            curve: Curves.easeInOut,
            width: _down ? 92 : 84,
            height: _down ? 8 : 10,
            decoration: BoxDecoration(
              color: platformColour,
              borderRadius: BorderRadius.circular(5),
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
    required this.nearest,
    required this.connecting,
    required this.enabled,
    required this.onTap,
  });

  final DiscoveredScale scale;
  final bool nearest;
  final bool connecting;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = [
      if (scale.modelCode != null && scale.modelCode!.isNotEmpty)
        scale.modelCode!,
      if (scale.rssi != null) nearest ? 'Nearest' : _signal(scale.rssi!),
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
      subtitle: detail.isEmpty
          ? null
          : Text(
              detail,
              style: MananuType.caption.copyWith(
                color: nearest ? MananuColors.brass : null,
                fontWeight: nearest ? FontWeight.w600 : null,
              ),
            ),
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
  const _Searching({required this.muted});

  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MananuSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: MananuSpacing.sm),
          Text(
            'Looking for scales…',
            style: MananuType.caption.copyWith(color: muted),
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
      padding: const EdgeInsets.symmetric(vertical: MananuSpacing.lg),
      child: Column(
        children: [
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
