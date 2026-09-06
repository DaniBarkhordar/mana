/// Onboarding.
///
/// Two things here are not cosmetic.
///
/// First, the consent step. Body composition is health data and therefore
/// special-category data under UK GDPR Article 9. The only realistic lawful
/// condition for a consumer app is explicit consent under Article 9(2)(a), and
/// "explicit" means a specific, affirmative act — not a pre-ticked box, not
/// consent bundled into the terms of service, and not consent implied by using
/// the app. The user must be able to decline body composition and still use the
/// product, which is why declining leaves weight and food logging fully working.
///
/// Second, the price is shown before the questionnaire, not after. The most
/// common complaint about the leading competitor is that it collects a page of
/// personal data and only then reveals what it costs. Beyond being a poor
/// experience, drip pricing has been prohibited in the UK since April 2025.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bia/equations.dart';
import '../../core/data/providers.dart';
import '../../theme/tokens.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  double _heightCm = 175;
  int _age = 35;
  Sex? _sex;
  ActivityLevel _activity = ActivityLevel.lowActive;
  bool _consentBodyComposition = false;

  static const _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    final sex = _sex;
    if (sex == null) return;
    ref.read(userProfileProvider.notifier).state = UserProfile(
      heightCm: _heightCm,
      ageYears: _age,
      sex: sex,
      activity: _activity,
    );
    widget.onComplete();
  }

  bool get _canAdvance => switch (_page) {
        0 => true,
        1 => _sex != null,
        2 => true,
        3 => true,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(MananuSpacing.lg),
              child: Row(
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _page
                              ? MananuColors.brass
                              : Theme.of(context).colorScheme.outline,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _WelcomePage(),
                  _AboutYouPage(
                    heightCm: _heightCm,
                    age: _age,
                    sex: _sex,
                    onHeight: (v) => setState(() => _heightCm = v),
                    onAge: (v) => setState(() => _age = v),
                    onSex: (v) => setState(() => _sex = v),
                  ),
                  _ActivityPage(
                    activity: _activity,
                    onChanged: (v) => setState(() => _activity = v),
                  ),
                  _ConsentPage(
                    granted: _consentBodyComposition,
                    onChanged: (v) =>
                        setState(() => _consentBodyComposition = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MananuSpacing.xl),
              child: FilledButton(
                onPressed: _canAdvance ? _next : null,
                child: Text(_page == _pageCount - 1 ? 'Start' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Weigh it.\nDon\'t guess it.', style: MananuType.display),
          const SizedBox(height: MananuSpacing.lg),
          Text(
            'Photo calorie apps guess how much is on your plate, and portion '
            'size is where they go wrong. Mananu uses the camera only to work '
            'out what the food is. The amount comes off the scale.',
            style: MananuType.body.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: MananuSpacing.xxl),

          // Pricing stated up front, before any personal data is collected.
          Container(
            padding: const EdgeInsets.all(MananuSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: MananuSpacing.radiusMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What it costs', style: MananuType.heading),
                const SizedBox(height: MananuSpacing.sm),
                Text(
                  'Weighing, barcode scanning, manual logging and your body '
                  'trends are free, forever, with no account limits.\n\n'
                  'Photo recognition is free for 30 scans a month. Beyond that, '
                  'Plus is £4.99 a month or £39.99 a year. You can cancel in two '
                  'taps and nothing renews without telling you first.',
                  style: MananuType.caption.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutYouPage extends StatelessWidget {
  const _AboutYouPage({
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.onHeight,
    required this.onAge,
    required this.onSex,
  });

  final double heightCm;
  final int age;
  final Sex? sex;
  final ValueChanged<double> onHeight;
  final ValueChanged<int> onAge;
  final ValueChanged<Sex> onSex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
      children: [
        const Text('About you', style: MananuType.title),
        const SizedBox(height: MananuSpacing.sm),
        Text(
          'The published equations Mananu uses need these three inputs '
          'alongside the impedance reading from your scale. Nothing here is '
          'used for anything else.',
          style: MananuType.body.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: MananuSpacing.xl),
        const Text('Height', style: MananuType.label),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: heightCm,
                min: 120,
                max: 220,
                divisions: 100,
                onChanged: onHeight,
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                '${heightCm.round()} cm',
                textAlign: TextAlign.right,
                style: MananuType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: MananuSpacing.lg),
        const Text('Age', style: MananuType.label),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: age.toDouble(),
                min: 18,
                max: 95,
                divisions: 77,
                onChanged: (v) => onAge(v.round()),
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                '$age',
                textAlign: TextAlign.right,
                style: MananuType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: MananuSpacing.xl),
        const Text('Sex', style: MananuType.label),
        const SizedBox(height: MananuSpacing.sm),
        Row(
          children: [
            for (final s in Sex.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: MananuSpacing.sm),
                  child: OutlinedButton(
                    onPressed: () => onSex(s),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: sex == s
                          ? MananuColors.brassSoft
                          : Colors.transparent,
                      side: BorderSide(
                        color: sex == s ? MananuColors.brass : scheme.outline,
                      ),
                    ),
                    child: Text(s == Sex.male ? 'Male' : 'Female'),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: MananuSpacing.md),
        Text(
          'The bioimpedance equations were fitted on male and female groups '
          'separately and there is no published coefficient for anything else. '
          'This is a measurement setting, not a profile field.',
          style: MananuType.caption.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _ActivityPage extends StatelessWidget {
  const _ActivityPage({required this.activity, required this.onChanged});

  final ActivityLevel activity;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
      children: [
        const Text('How active are you?', style: MananuType.title),
        const SizedBox(height: MananuSpacing.sm),
        Text(
          'These bands come from the Dietary Reference Intakes for Energy, '
          'measured with doubly-labelled water — not the usual fitness-app '
          'multipliers, which have no published source.',
          style: MananuType.body.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: MananuSpacing.xl),
        for (final level in ActivityLevel.values)
          Padding(
            padding: const EdgeInsets.only(bottom: MananuSpacing.md),
            child: InkWell(
              onTap: () => onChanged(level),
              borderRadius: MananuSpacing.radiusMd,
              child: Container(
                padding: const EdgeInsets.all(MananuSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: MananuSpacing.radiusMd,
                  color: activity == level
                      ? MananuColors.brassSoft
                      : Colors.transparent,
                  border: Border.all(
                    color:
                        activity == level ? MananuColors.brass : scheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(level.label, style: MananuType.bodyStrong),
                          Text(
                            level.description,
                            style: MananuType.caption.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '×${level.pal}',
                      style: MananuType.number.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({required this.granted, required this.onChanged});

  final bool granted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
      children: [
        const Text('Your body data', style: MananuType.title),
        const SizedBox(height: MananuSpacing.sm),
        Text(
          'Body composition counts as health data in UK and EU law, which means '
          'we have to ask you separately and clearly before we process it. This '
          'is that ask.',
          style: MananuType.body.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: MananuSpacing.xl),
        const _Fact(
          icon: Icons.public_off,
          title: 'Stored in the UK and EU only',
          body: 'Your data never goes to the scale manufacturer or to any '
              'server outside the UK and EU.',
        ),
        const _Fact(
          icon: Icons.phone_iphone,
          title: 'Worked out on your phone',
          body: 'Body composition is calculated on your device from published '
              'equations, not sent away to be computed.',
        ),
        const _Fact(
          icon: Icons.delete_outline,
          title: 'Deleted when you say so',
          body: 'Delete your account in Settings and it is erased, not hidden. '
              'You can export everything first.',
        ),
        const SizedBox(height: MananuSpacing.lg),

        // Unticked by default. Explicit consent means an affirmative act.
        CheckboxListTile(
          value: granted,
          onChanged: (v) => onChanged(v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'I agree to Mananu processing my body composition data',
            style: MananuType.bodyStrong,
          ),
          subtitle: Text(
            'You can withdraw this at any time in Settings.',
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: MananuSpacing.md),
        Container(
          padding: const EdgeInsets.all(MananuSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: MananuSpacing.radiusMd,
          ),
          child: Text(
            granted
                ? 'You can still use everything if you change your mind later — '
                    'weight and food logging keep working without this.'
                : 'That is fine. Weight, food logging and your kitchen scale '
                    'all work without it. You just will not see body '
                    'composition.',
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: MananuSpacing.xl),
        Text(
          'Mananu is not a medical device. It does not diagnose, treat or '
          'monitor any disease. Do not use the body scale if you have a '
          'pacemaker or another implanted electronic device.',
          style: MananuType.caption.copyWith(color: MananuColors.warning),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: MananuSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: MananuColors.brass),
          const SizedBox(width: MananuSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MananuType.bodyStrong),
                Text(
                  body,
                  style: MananuType.caption.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
