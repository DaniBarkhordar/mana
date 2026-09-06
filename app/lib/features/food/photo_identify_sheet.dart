/// Photograph the plate. The camera names the components; the scale weighs
/// them. Nothing here asks a model how many grams are on the plate, which is
/// where the rest of the category spends its error budget.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/food/food_identifier.dart';
import '../../core/nutrition/models.dart';
import '../../theme/tokens.dart';

/// What the sheet hands back. A food to weigh now, or a request to log
/// cooking fat, plus the whole scan so the screen can offer the other
/// components without another photo.
class PhotoOutcome {
  const PhotoOutcome({
    required this.result,
    required this.matched,
    this.picked,
    this.wantsCookingFat = false,
  });

  final IdentifyResult result;
  final List<MatchedCandidate> matched;
  final FoodItem? picked;
  final bool wantsCookingFat;
}

class PhotoIdentifySheet extends ConsumerStatefulWidget {
  const PhotoIdentifySheet({super.key, this.measuredGrams, this.hint});

  final double? measuredGrams;
  final String? hint;

  static Future<PhotoOutcome?> show(
    BuildContext context, {
    double? measuredGrams,
    String? hint,
  }) =>
      showModalBottomSheet<PhotoOutcome>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) =>
            PhotoIdentifySheet(measuredGrams: measuredGrams, hint: hint),
      );

  @override
  ConsumerState<PhotoIdentifySheet> createState() => _PhotoIdentifySheetState();
}

enum _Stage { consent, capturing, identifying, results, cancelled }

class _PhotoIdentifySheetState extends ConsumerState<PhotoIdentifySheet> {
  _Stage _stage = _Stage.capturing;
  Uint8List? _photo;
  IdentifyResult? _result;
  List<MatchedCandidate> _matched = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final services = await ref.read(appServicesProvider.future);
    final consent =
        await services.profiles.latestConsent(ConsentRecord.photoRecognition);
    if (!mounted) return;
    if (consent?.granted != true) {
      setState(() => _stage = _Stage.consent);
      return;
    }
    await _capture();
  }

  /// Explicit, separate, and names the provider: Apple 5.1.2(i) requires
  /// permission before data goes to third-party AI, and a photo of someone's
  /// plate is their data.
  Future<void> _grantConsent() async {
    final services = await ref.read(appServicesProvider.future);
    await services.profiles.recordConsent(
      ConsentRecord(
        purpose: ConsentRecord.photoRecognition,
        policyVersion: ConsentRecord.currentPolicyVersion,
        granted: true,
        grantedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    await _capture();
  }

  Future<void> _capture() async {
    setState(() => _stage = _Stage.capturing);
    final bytes = await ref.read(photoCaptureProvider)();
    if (!mounted) return;
    if (bytes == null) {
      Navigator.of(context).pop();
      return;
    }
    _photo = bytes;
    setState(() => _stage = _Stage.identifying);

    final prepared = prepareImageForIdentification(bytes);
    if (prepared == null) {
      setState(() {
        _result = const IdentifyResult(
          candidates: [],
          note: 'That photo could not be read. Try again in better light.',
        );
        _stage = _Stage.results;
      });
      return;
    }

    final services = await ref.read(appServicesProvider.future);
    final recent = await services.userFoods.recentlyLogged(limit: 25);
    final now = DateTime.now();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final request = IdentifyRequest(
      imageBase64: prepared,
      localTime:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      locale: locale.toLanguageTag(),
      recentFoods: [for (final f in recent) f.displayName],
      hint: widget.hint,
      measuredGrams: widget.measuredGrams,
    );
    final result = await ref.read(foodIdentifierProvider).identify(request);
    final matched = await (await ref.read(foodMatcherProvider.future))
        .match(result.candidates);
    if (!mounted) return;
    setState(() {
      _result = result;
      _matched = matched;
      _stage = _Stage.results;
    });
  }

  void _pick(MatchedCandidate m, FoodItem food) {
    Navigator.of(context).pop(
      PhotoOutcome(result: _result!, matched: _matched, picked: food),
    );
  }

  void _cookingFat() {
    Navigator.of(context).pop(
      PhotoOutcome(result: _result!, matched: _matched, wantsCookingFat: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: switch (_stage) {
        _Stage.consent => _ConsentView(
            onAccept: _grantConsent,
            onDecline: () => Navigator.of(context).pop(),
          ),
        _Stage.capturing => const _Working(label: 'Opening the camera'),
        _Stage.identifying => _Working(
            label: 'Working out what it is',
            photo: _photo,
          ),
        _Stage.results => _Results(
            result: _result!,
            matched: _matched,
            photo: _photo,
            onPick: _pick,
            onCookingFat: _cookingFat,
            onRetake: _capture,
          ),
        _Stage.cancelled => const SizedBox.shrink(),
      },
    );
  }
}

class _ConsentView extends StatelessWidget {
  const _ConsentView({required this.onAccept, required this.onDecline});

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.xl,
        MananuSpacing.sm,
        MananuSpacing.xl,
        MananuSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Photos and the AI provider', style: MananuType.title),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            'To work out what a food is, Mananu sends the photo to '
            '${VisionConfig.providerName}. That is all it sends — no name, no '
            'weight, no body data — and the photo is not kept by Mananu.\n\n'
            'The amount always comes from your scale. The photo is never used '
            'to guess how much is on the plate.',
            style: MananuType.body.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          FilledButton(
            onPressed: onAccept,
            child: const Text('Allow photo recognition'),
          ),
          const SizedBox(height: MananuSpacing.sm),
          OutlinedButton(
            onPressed: onDecline,
            child: const Text('Not now, I will search'),
          ),
          const SizedBox(height: MananuSpacing.md),
          Text(
            'You can change this any time in Settings.',
            textAlign: TextAlign.center,
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working({required this.label, this.photo});

  final String label;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(MananuSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (photo != null) ...[
            ClipRRect(
              borderRadius: MananuSpacing.radiusMd,
              child: Image.memory(
                photo!,
                height: 160,
                width: 160,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(height: MananuSpacing.xl),
          ],
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: MananuSpacing.lg),
          Text(
            label,
            style: MananuType.body.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.result,
    required this.matched,
    required this.photo,
    required this.onPick,
    required this.onCookingFat,
    required this.onRetake,
  });

  final IdentifyResult result;
  final List<MatchedCandidate> matched;
  final Uint8List? photo;
  final void Function(MatchedCandidate, FoodItem) onPick;
  final VoidCallback onCookingFat;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fatHints = [
      for (final m in matched)
        if (m.candidate.likelyAddedFat != null) m.candidate.likelyAddedFat!,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
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
          Row(
            children: [
              if (photo != null)
                ClipRRect(
                  borderRadius: MananuSpacing.radiusSm,
                  child: Image.memory(
                    photo!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              if (photo != null) const SizedBox(width: MananuSpacing.md),
              Expanded(
                child: Text(
                  matched.isEmpty
                      ? 'Nothing recognised'
                      : 'Tap what you are weighing now',
                  style: MananuType.title,
                ),
              ),
              IconButton(
                tooltip: 'Retake',
                onPressed: onRetake,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (result.note != null) ...[
            const SizedBox(height: MananuSpacing.sm),
            Text(
              result.note!,
              style: MananuType.caption.copyWith(
                color: result.degraded || result.quotaExceeded
                    ? MananuColors.warning
                    : scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: MananuSpacing.lg),
          for (final m in matched) _CandidateCard(matched: m, onPick: onPick),
          if (fatHints.isNotEmpty) ...[
            const SizedBox(height: MananuSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.water_drop_outlined,
                  color: MananuColors.brass,
                ),
                title:
                    const Text('Cooked in fat?', style: MananuType.bodyStrong),
                subtitle: Text(
                  'Looks like ${fatHints.first}. Weigh the pan before and '
                  'after to log what the food absorbed — the photo cannot '
                  'see it.',
                  style: MananuType.caption.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                onTap: onCookingFat,
              ),
            ),
          ],
          const SizedBox(height: MananuSpacing.md),
          Text(
            'The photo only says what the food is. The amount is whatever '
            'the scale reads when you capture it.',
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.matched, required this.onPick});

  final MatchedCandidate matched;
  final void Function(MatchedCandidate, FoodItem) onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = matched.candidate;
    final best = matched.best;
    final confidence = c.confidence >= 0.75
        ? 'Likely'
        : c.confidence >= 0.45
            ? 'Possibly'
            : 'Unsure';

    return Card(
      margin: const EdgeInsets.only(bottom: MananuSpacing.sm),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Expanded(child: Text(c.name, style: MananuType.bodyStrong)),
                Text(
                  confidence,
                  style: MananuType.label.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            subtitle: best == null
                ? Text(
                    'Not in the food database — search for it instead.',
                    style: MananuType.caption.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  )
                : Text(
                    '${best.displayName} · ${best.per100g.kcal.round()} kcal '
                    '/ 100 g · ${best.source.label}',
                    style: MananuType.caption.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
            trailing: best == null ? null : const Icon(Icons.chevron_right),
            onTap: best == null ? null : () => onPick(matched, best),
          ),
          if (matched.matches.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MananuSpacing.lg,
                0,
                MananuSpacing.lg,
                MananuSpacing.md,
              ),
              child: Wrap(
                spacing: MananuSpacing.sm,
                runSpacing: MananuSpacing.sm,
                children: [
                  for (final alt in matched.matches.skip(1))
                    ActionChip(
                      label: Text(
                        alt.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      labelStyle: MananuType.caption,
                      onPressed: () => onPick(matched, alt),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
