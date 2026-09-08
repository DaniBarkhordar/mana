/// The live kitchen-scale readout: one number, a settle bar, and a line that
/// says whether the scale is there.
///
/// Shared by the weigh screen and the cooking-fat sheet so that "what a live
/// reading looks like" is defined once — quiet while the load cell is still
/// moving, full strength and a brass bar once it has settled. The user should
/// be able to tell at a glance, without reading a word.
library;

import 'package:flutter/material.dart';

import '../../core/scale/scale_driver.dart';
import '../../theme/tokens.dart';

class ScaleReadout extends StatelessWidget {
  const ScaleReadout({
    super.key,
    required this.grams,
    required this.delta,
    required this.isStable,
    required this.connection,
    this.needsPairing = false,
    this.onPair,
  });

  final double grams;

  /// Grams added since the last captured ingredient. Shown as a brass pill
  /// when positive; pass zero to hide it.
  final double delta;
  final bool isStable;
  final ScaleConnectionState? connection;

  /// No kitchen scale has been chosen on this phone yet.
  final bool needsPairing;
  final VoidCallback? onPair;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final connected = connection == ScaleConnectionState.connected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.xl,
        MananuSpacing.lg,
        MananuSpacing.xl,
        MananuSpacing.xl,
      ),
      color: scheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? MananuColors.measured : MananuColors.mist,
                ),
              ),
              const SizedBox(width: MananuSpacing.sm),
              Text(
                connected
                    ? 'Scale connected'
                    : needsPairing
                        ? 'No scale paired'
                        : 'Looking for your scale',
                style: MananuType.label.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              if (needsPairing && !connected) ...[
                const SizedBox(width: MananuSpacing.sm),
                GestureDetector(
                  onTap: onPair,
                  child: Text(
                    'PAIR',
                    style: MananuType.label.copyWith(color: MananuColors.brass),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: MananuSpacing.lg),

          // The readout. Tabular figures so digits do not shuffle sideways as
          // the number climbs, and a colour that only settles once the reading
          // has settled — the user should be able to tell at a glance, without
          // reading a word.
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: MananuType.readout.copyWith(
              color: isStable
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.45),
            ),
            child: Text(grams.toStringAsFixed(grams >= 1000 ? 0 : 1)),
          ),
          const SizedBox(height: MananuSpacing.sm),
          // Settles with the reading: brass when the scale has locked, quiet
          // while it is still moving.
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: isStable ? 72 : 28,
            height: 3,
            decoration: BoxDecoration(
              color: isStable
                  ? MananuColors.brass
                  : scheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            isStable ? 'grams · settled' : 'grams',
            style: MananuType.label.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),

          if (delta > 0.5) ...[
            const SizedBox(height: MananuSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MananuSpacing.md,
                vertical: MananuSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: MananuColors.brassSoft,
                borderRadius: MananuSpacing.radiusSm,
              ),
              child: Text(
                '+${delta.toStringAsFixed(1)} g since last ingredient',
                style: MananuType.caption.copyWith(
                  color: MananuColors.brass,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
