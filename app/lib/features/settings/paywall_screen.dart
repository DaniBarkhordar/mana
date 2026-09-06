import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';

/// Mananu Plus.
///
/// Honest by design: the free tier is the whole product, and the sheet says
/// so before it says anything else. Plus is for the people who photograph
/// every plate, cook from recipes, and want the app to learn their portions.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.reason});

  /// Why the sheet opened, shown under the heading: "You've used this
  /// month's 30 free photo scans."
  final String? reason;

  static Future<void> show(BuildContext context, {String? reason}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => PaywallScreen(reason: reason),
        ),
      );

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<PlusOffer>? _offers;
  PlusOffer? _chosen;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final service = await ref.read(entitlementServiceProvider.future);
      final offers = await service.offers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _chosen = offers.isEmpty ? null : offers.first;
      });
    } on Object {
      if (mounted) setState(() => _offers = const []);
    }
  }

  Future<void> _buy() async {
    final offer = _chosen;
    if (offer == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = await ref.read(entitlementServiceProvider.future);
      final status = await service.purchase(offer);
      if (!mounted) return;
      if (status.isPlus) Navigator.of(context).pop();
    } on PurchaseCancelled {
      // Their call.
    } on Object {
      if (mounted) {
        setState(
          () => _error = 'The store did not complete the purchase. Nothing '
              'was charged; try again in a moment.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = await ref.read(entitlementServiceProvider.future);
      final status = await service.restore();
      if (!mounted) return;
      if (status.isPlus) {
        Navigator.of(context).pop();
      } else {
        setState(
          () => _error = 'No Plus subscription found for this store '
              'account.',
        );
      }
    } on Object {
      if (mounted) setState(() => _error = 'Could not reach the store.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final plus = ref.watch(plusStatusProvider).valueOrNull ?? PlusStatus.free;
    final configured = BillingConfig.isConfigured;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Mananu Plus'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.lg,
          MananuSpacing.sm,
          MananuSpacing.lg,
          MananuSpacing.huge,
        ),
        children: [
          const MananuMark(height: 28),
          const SizedBox(height: MananuSpacing.lg),
          Text(
            plus.isPlus ? 'You have Plus' : 'The scale is free. Forever.',
            style: MananuType.display.copyWith(fontSize: 32),
          ),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            widget.reason ??
                'Weighing, barcodes, manual logging, your targets and your '
                    'body trends never cost anything. Plus is for the parts '
                    'that cost us something to run.',
            style: MananuType.body.copyWith(color: muted),
          ),
          const SizedBox(height: MananuSpacing.xl),
          const _Included(),
          const SizedBox(height: MananuSpacing.xl),
          if (plus.isPlus)
            _PlusActive(status: plus)
          else if (!configured)
            Text(
              'Purchases are not available in this build.',
              style: MananuType.caption.copyWith(color: muted),
            )
          else if (_offers == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(MananuSpacing.xl),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else if (_offers!.isEmpty)
            Text(
              'Nothing is on sale right now. Try again shortly.',
              style: MananuType.caption.copyWith(color: muted),
            )
          else ...[
            for (final offer in _offers!) ...[
              _OfferCard(
                offer: offer,
                selected: offer == _chosen,
                onTap: () => setState(() => _chosen = offer),
              ),
              const SizedBox(height: MananuSpacing.sm),
            ],
            const SizedBox(height: MananuSpacing.sm),
            FilledButton(
              onPressed: _busy || _chosen == null ? null : _buy,
              child: Text(
                _chosen == null
                    ? 'Continue'
                    : 'Continue · ${_chosen!.priceString}'
                        '${_chosen!.period == PlusPeriod.annual ? ' a year' : _chosen!.period == PlusPeriod.monthly ? ' a month' : ''}',
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _restore,
              child: const Text('Restore purchases'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: MananuSpacing.sm),
            Text(
              _error!,
              style: MananuType.caption.copyWith(color: MananuColors.warning),
            ),
          ],
          const SizedBox(height: MananuSpacing.xl),
          Text(
            'Renews automatically until cancelled. Cancel any time in your '
            'App Store or Google Play subscriptions; nothing renews without '
            'the store telling you first. A Plus subscription bundled with a '
            'scale lapses to free when it ends, never to full price.',
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _Included extends StatelessWidget {
  const _Included();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    Widget row(IconData icon, String title, String detail) => Padding(
          padding: const EdgeInsets.symmetric(vertical: MananuSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: MananuColors.brass),
              const SizedBox(width: MananuSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: MananuType.bodyStrong),
                    Text(
                      detail,
                      style: MananuType.caption.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MananuSpacing.lg,
          vertical: MananuSpacing.sm,
        ),
        child: Column(
          children: [
            row(
              Icons.photo_camera_outlined,
              'Photo recognition without limit',
              'Thirty scans a month are free. Plus removes the limit. The '
                  'photo only ever names the food; the grams stay on the scale.',
            ),
            row(
              Icons.menu_book_outlined,
              'Recipes',
              'Weigh the ingredients once, weigh the finished dish, then log '
                  'a portion by weight forever.',
            ),
            row(
              Icons.tune,
              'Personal calibration',
              'After five weighings of a food, Mananu learns your usual '
                  'portion and says so when you estimate.',
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final PlusOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = switch (offer.period) {
      PlusPeriod.annual => 'Yearly',
      PlusPeriod.monthly => 'Monthly',
      PlusPeriod.other => offer.title,
    };
    final per = switch (offer.period) {
      PlusPeriod.annual => 'a year',
      PlusPeriod.monthly => 'a month',
      PlusPeriod.other => '',
    };
    return Material(
      color: selected ? MananuColors.brassSoft : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: MananuSpacing.radiusMd,
        side: BorderSide(
          color: selected ? MananuColors.brass : scheme.outline,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(MananuSpacing.lg),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? MananuColors.brass : scheme.outline,
              ),
              const SizedBox(width: MananuSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: MananuType.bodyStrong),
                    if (offer.period == PlusPeriod.annual)
                      Text(
                        'Two months free against monthly',
                        style: MananuType.caption.copyWith(
                          color: MananuColors.brass,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${offer.priceString} $per'.trim(),
                style: MananuType.number.copyWith(fontSize: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusActive extends StatelessWidget {
  const _PlusActive({required this.status});

  final PlusStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final until = status.expiresAt;
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.check_circle_outline,
          color: MananuColors.measured,
        ),
        title: const Text('Plus is active', style: MananuType.bodyStrong),
        subtitle: Text(
          until == null
              ? 'Thank you.'
              : status.willRenew
                  ? 'Renews ${_date(until)}. Manage it in your store '
                      'subscriptions.'
                  : 'Ends ${_date(until)} and then lapses to free.',
          style: MananuType.caption.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  static String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
