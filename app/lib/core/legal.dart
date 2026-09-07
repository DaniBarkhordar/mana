import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/tokens.dart';

/// Where the legal documents live.
///
/// App Review reads the paywall for a Terms of Use link and a Privacy Policy
/// link (Guideline 3.1.2), and Health Connect requires the privacy policy to
/// be reachable from the app (Play policy). Both are served from the marketing
/// domain; the drafts are docs/12-privacy-policy.md and the terms are with
/// counsel. Change the host here and nowhere else.
class Legal {
  const Legal._();

  static const host = 'https://getmananu.com';
  static final privacy = Uri.parse('$host/privacy');
  static final terms = Uri.parse('$host/terms');

  /// Apple's standard EULA applies to App Store subscriptions unless the app
  /// supplies its own; the link is required on the paywall either way.
  static final appleEula = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  static Future<void> open(Uri uri) async {
    // External so the policy opens in the browser with its own address bar,
    // where a person can check the domain, rather than in a sheet that could
    // show anything.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// "Terms · Privacy" as a quiet row of links, for paywalls and About.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.alignment = WrapAlignment.start});

  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final style = MananuType.caption.copyWith(
      color: muted,
      decoration: TextDecoration.underline,
      decorationColor: muted,
    );
    return Wrap(
      alignment: alignment,
      spacing: MananuSpacing.md,
      children: [
        _Link('Terms of use', Legal.terms, style),
        _Link('Privacy policy', Legal.privacy, style),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.uri, this.style);

  final String label;
  final Uri uri;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        child: InkWell(
          onTap: () => Legal.open(uri),
          borderRadius: MananuSpacing.radiusSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: MananuSpacing.xs,
              horizontal: MananuSpacing.xs,
            ),
            child: Text(label, style: style),
          ),
        ),
      );
}
