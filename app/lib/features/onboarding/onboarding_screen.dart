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
///
/// The flow: welcome, about you, your goal, target and pace (skipped when the
/// goal is to hold steady), activity, consent, then a summary that shows the
/// daily target the app will start from and says plainly that it moves with
/// each reading. Everything is computed on the phone from the answers; the
/// profile is written once, at Start.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/bia/equations.dart';
import '../../core/data/providers.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';
import 'goal_controls.dart';

enum _Step { welcome, aboutYou, goal, target, activity, consent, summary }

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
  DateTime _dateOfBirth = UserProfile.dateOfBirthForAge(35);
  Sex? _sex;

  /// Self-reported, and stored as such. The first reading replaces it.
  double _weightNowKg = 75;
  GoalKind? _goal;
  double? _targetWeightKg;
  double _paceKgPerWeek = 0.5;
  MacroSplit _split = MacroSplit.balanced;
  ActivityLevel _activity = ActivityLevel.lowActive;
  bool _consentBodyComposition = false;

  /// The pages in play. The target page only exists for a loss or a gain.
  List<_Step> get _steps => [
        _Step.welcome,
        _Step.aboutYou,
        _Step.goal,
        if (_goal != null && _goal != GoalKind.maintain) _Step.target,
        _Step.activity,
        _Step.consent,
        _Step.summary,
      ];

  _Step get _current => _steps[_page.clamp(0, _steps.length - 1)];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canAdvance => switch (_current) {
        _Step.aboutYou => _sex != null,
        _Step.goal => _goal != null,
        _ => true,
      };

  void _next() {
    if (_page == _steps.length - 1) {
      unawaited(_finish());
      return;
    }
    unawaited(
      _controller.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  void _back() {
    if (_page == 0) return;
    unawaited(
      _controller.animateToPage(
        _page - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  void _chooseGoal(GoalKind goal) {
    setState(() {
      _goal = goal;
      // A target chosen for a loss makes no sense for a gain: start again
      // from a sensible default in the new direction.
      _targetWeightKg = goal == GoalKind.maintain
          ? null
          : TargetWeightControl.defaultFor(goal, _weightNowKg);
    });
  }

  /// The profile as it will be saved, for the summary's live target. Height,
  /// age and sex feed Mifflin-St Jeor; there is no reading yet, so no
  /// fat-free mass.
  UserProfile get _draft => UserProfile(
        id: 'draft',
        heightCm: _heightCm,
        dateOfBirth: _dateOfBirth,
        sex: _sex ?? Sex.male,
        activity: _activity,
        goal: _goal ?? GoalKind.maintain,
        targetWeightKg: _targetWeightKg,
        paceKgPerWeek: _paceKgPerWeek,
        macroSplit: _split,
      );

  EnergyTarget get _target =>
      energyTargetFor(profile: _draft, latest: null, weightKg: _weightNowKg);

  /// Writes the profile and the consent decision to SQLite. The profile stream
  /// then moves the app on; nothing here needs a network.
  Future<void> _finish() async {
    final sex = _sex;
    final goal = _goal;
    if (sex == null || goal == null) return;
    final services = await ref.read(appServicesProvider.future);
    final now = DateTime.now();
    await services.profiles.save(
      heightCm: _heightCm,
      dateOfBirth: _dateOfBirth,
      sex: sex,
      activity: _activity,
      goal: goal,
      targetWeightKg: goal == GoalKind.maintain ? null : _targetWeightKg,
      paceKgPerWeek: goal == GoalKind.maintain ? null : _paceKgPerWeek,
      macroSplit: _split,
    );
    // The typed-in weight is a measurement of a kind, so it goes where every
    // measurement goes, labelled with where it came from. The first reading
    // off the scale supersedes it (CLAUDE.md rule 7).
    await services.observations.record(
      kind: 'weight_kg',
      value: _weightNowKg,
      unit: 'kg',
      source: selfReportedSource,
      method: 'self_reported',
      takenAt: now,
    );
    // Recorded either way. A refusal is a decision too, and the next reading
    // must know it.
    await services.profiles.recordConsent(
      ConsentRecord(
        purpose: ConsentRecord.bodyComposition,
        policyVersion: ConsentRecord.currentPolicyVersion,
        granted: _consentBodyComposition,
        grantedAt: now,
      ),
    );
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final isLast = _page == steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Progress(count: steps.length, page: _page, onBack: _back),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final step in steps) _buildStep(step),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MananuSpacing.xl,
                MananuSpacing.md,
                MananuSpacing.xl,
                MananuSpacing.xl,
              ),
              child: FilledButton(
                onPressed: _canAdvance ? _next : null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    isLast ? 'Start' : 'Continue',
                    key: ValueKey(isLast),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_Step step) => switch (step) {
        _Step.welcome => const _WelcomePage(key: ValueKey(_Step.welcome)),
        _Step.aboutYou => _AboutYouPage(
            key: const ValueKey(_Step.aboutYou),
            heightCm: _heightCm,
            dateOfBirth: _dateOfBirth,
            sex: _sex,
            weightKg: _weightNowKg,
            onHeight: (v) => setState(() => _heightCm = v),
            onDateOfBirth: (v) => setState(() => _dateOfBirth = v),
            onSex: (v) => setState(() => _sex = v),
            onWeight: (v) => setState(() {
              _weightNowKg = v;
              final goal = _goal;
              if (goal != null && goal != GoalKind.maintain) {
                _targetWeightKg = TargetWeightControl.defaultFor(goal, v);
              }
            }),
          ),
        _Step.goal => _GoalPage(
            key: const ValueKey(_Step.goal),
            goal: _goal,
            onChanged: _chooseGoal,
          ),
        _Step.target => _TargetPage(
            key: const ValueKey(_Step.target),
            goal: _goal ?? GoalKind.lose,
            currentKg: _weightNowKg,
            targetKg: _targetWeightKg ??
                TargetWeightControl.defaultFor(
                  _goal ?? GoalKind.lose,
                  _weightNowKg,
                ),
            paceKgPerWeek: _paceKgPerWeek,
            onTarget: (v) => setState(() => _targetWeightKg = v),
            onPace: (v) => setState(() => _paceKgPerWeek = v),
          ),
        _Step.activity => _ActivityPage(
            key: const ValueKey(_Step.activity),
            activity: _activity,
            onChanged: (v) => setState(() => _activity = v),
          ),
        _Step.consent => _ConsentPage(
            key: const ValueKey(_Step.consent),
            granted: _consentBodyComposition,
            onChanged: (v) => setState(() => _consentBodyComposition = v),
          ),
        _Step.summary => _SummaryPage(
            key: const ValueKey(_Step.summary),
            target: _target,
            split: _split,
            onSplit: (v) => setState(() => _split = v),
          ),
      };
}

/// One brass bar per step, filled up to the current one, and a way back.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.count,
    required this.page,
    required this.onBack,
  });

  final int count;
  final int page;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.sm,
        MananuSpacing.sm,
        MananuSpacing.lg,
        MananuSpacing.sm,
      ),
      child: Row(
        children: [
          // Kept in the layout on the first page so the bars do not jump.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: page == 0 ? 0 : 1,
            child: IconButton(
              onPressed: page == 0 ? null : onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
          ),
          for (var i = 0; i < count; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= page ? MananuColors.brass : scheme.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A page title with its one-line explanation under it.
class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: MananuSpacing.sm),
        Text(
          title,
          style: MananuType.display.copyWith(
            fontSize: 30,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: MananuSpacing.sm),
        Text(
          body,
          style: MananuType.body.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: MananuSpacing.xl),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Centred on a tall phone; scrolls on a short one or with large text.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MananuMark(height: 28),
              const SizedBox(height: MananuSpacing.xl),
              const Text(
                'Weigh it.\nDon\'t guess it.',
                style: MananuType.display,
              ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(MananuSpacing.lg),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutYouPage extends StatelessWidget {
  const _AboutYouPage({
    super.key,
    required this.heightCm,
    required this.dateOfBirth,
    required this.sex,
    required this.weightKg,
    required this.onHeight,
    required this.onDateOfBirth,
    required this.onSex,
    required this.onWeight,
  });

  final double heightCm;
  final DateTime dateOfBirth;
  final Sex? sex;
  final double weightKg;
  final ValueChanged<double> onHeight;
  final ValueChanged<DateTime> onDateOfBirth;
  final ValueChanged<Sex> onSex;
  final ValueChanged<double> onWeight;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth,
      // The equations are validated from 18 up; nobody is 120.
      firstDate: DateTime(now.year - 120, 1, 1),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Date of birth',
    );
    if (picked != null) onDateOfBirth(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
      children: [
        const _PageHeading(
          title: 'About you',
          body: 'The published equations Mananu uses need these alongside the '
              'impedance reading from your scale. Nothing here is used for '
              'anything else.',
        ),
        _SliderField(
          label: 'Height',
          value: '${heightCm.round()} cm',
          slider: Slider(
            value: heightCm,
            min: 120,
            max: 220,
            divisions: 100,
            onChanged: onHeight,
          ),
        ),
        const SizedBox(height: MananuSpacing.lg),
        Text('DATE OF BIRTH', style: MananuType.label.copyWith(color: muted)),
        const SizedBox(height: MananuSpacing.sm),
        SelectableCard(
          selected: false,
          onTap: () => _pickDate(context),
          padding: const EdgeInsets.symmetric(
            horizontal: MananuSpacing.lg,
            vertical: MananuSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('d MMMM yyyy').format(dateOfBirth),
                  style: MananuType.number.copyWith(
                    fontSize: 17,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${_ageFrom(dateOfBirth)} years',
                style: MananuType.caption.copyWith(color: muted),
              ),
              const SizedBox(width: MananuSpacing.sm),
              Icon(Icons.edit_calendar_outlined, size: 18, color: muted),
            ],
          ),
        ),
        const SizedBox(height: MananuSpacing.lg),
        _SliderField(
          label: 'Weight now, roughly',
          value: '${weightKg.toStringAsFixed(1)} kg',
          slider: Slider(
            value: weightKg,
            min: 35,
            max: 200,
            divisions: 330,
            onChanged: onWeight,
          ),
          caption: 'Only to start the sums. Your first reading on the scale '
              'replaces it, and it is labelled as typed in until then.',
        ),
        const SizedBox(height: MananuSpacing.xl),
        Text('SEX', style: MananuType.label.copyWith(color: muted)),
        const SizedBox(height: MananuSpacing.sm),
        Row(
          children: [
            for (final s in Sex.values) ...[
              Expanded(
                child: SelectableCard(
                  selected: sex == s,
                  onTap: () => onSex(s),
                  child: Center(
                    child: Text(
                      s == Sex.male ? 'Male' : 'Female',
                      style: MananuType.bodyStrong.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              if (s != Sex.values.last) const SizedBox(width: MananuSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: MananuSpacing.md),
        Text(
          'The bioimpedance equations were fitted on male and female groups '
          'separately and there is no published coefficient for anything else. '
          'This is a measurement setting, not a profile field.',
          style: MananuType.caption.copyWith(color: muted),
        ),
        const SizedBox(height: MananuSpacing.xl),
      ],
    );
  }
}

/// Age today from a date of birth, the way [UserProfile.ageOn] counts it.
int _ageFrom(DateTime dateOfBirth) => UserProfile(
      id: 'draft',
      heightCm: 0,
      dateOfBirth: dateOfBirth,
      sex: Sex.male,
    ).ageYears;

/// A labelled slider with its value set in tabular figures at the right.
class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.slider,
    this.caption,
  });

  final String label;
  final String value;
  final Widget slider;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: MananuType.label.copyWith(color: muted),
              ),
            ),
            Text(
              value,
              style: MananuType.number.copyWith(
                fontSize: 17,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        slider,
        if (caption != null)
          Text(
            caption!,
            style: MananuType.caption.copyWith(color: muted),
          ),
      ],
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({super.key, required this.goal, required this.onChanged});

  final GoalKind? goal;
  final ValueChanged<GoalKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
      children: [
        const _PageHeading(
          title: 'What are you here for?',
          body: 'This sets the daily target. You can change it any time in '
              'Settings, and it is recomputed from every reading, so it '
              'follows your weight rather than the other way round.',
        ),
        GoalCards(selected: goal, onChanged: onChanged),
      ],
    );
  }
}

class _TargetPage extends StatelessWidget {
  const _TargetPage({
    super.key,
    required this.goal,
    required this.currentKg,
    required this.targetKg,
    required this.paceKgPerWeek,
    required this.onTarget,
    required this.onPace,
  });

  final GoalKind goal;
  final double currentKg;
  final double targetKg;
  final double paceKgPerWeek;
  final ValueChanged<double> onTarget;
  final ValueChanged<double> onPace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
      children: [
        _PageHeading(
          title: goal == GoalKind.lose ? 'Where to, and how fast' : 'How much',
          body: goal == GoalKind.lose
              ? 'A steadier pace is easier to hold and keeps more muscle. '
                  'Whatever you pick, the target never drops below your '
                  'resting rate.'
              : 'A modest surplus puts on more of what you want. Faster '
                  'mostly adds fat.',
        ),
        Text('TARGET WEIGHT', style: MananuType.label.copyWith(color: muted)),
        const SizedBox(height: MananuSpacing.sm),
        TargetWeightControl(
          goal: goal,
          currentKg: currentKg,
          targetKg: targetKg,
          onChanged: onTarget,
        ),
        const SizedBox(height: MananuSpacing.xl),
        Text('PACE', style: MananuType.label.copyWith(color: muted)),
        const SizedBox(height: MananuSpacing.sm),
        PaceControl(
          goal: goal,
          paceKgPerWeek: paceKgPerWeek,
          currentKg: currentKg,
          targetKg: targetKg,
          onChanged: onPace,
        ),
        const SizedBox(height: MananuSpacing.xl),
      ],
    );
  }
}

class _ActivityPage extends StatelessWidget {
  const _ActivityPage({
    super.key,
    required this.activity,
    required this.onChanged,
  });

  final ActivityLevel activity;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
      children: [
        const _PageHeading(
          title: 'How active are you?',
          body: 'These bands come from the Dietary Reference Intakes for '
              'Energy, measured with doubly-labelled water — not the usual '
              'fitness-app multipliers, which have no published source.',
        ),
        for (final level in ActivityLevel.values)
          Padding(
            padding: const EdgeInsets.only(bottom: MananuSpacing.md),
            child: SelectableCard(
              selected: activity == level,
              onTap: () => onChanged(level),
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
      ],
    );
  }
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({
    super.key,
    required this.granted,
    required this.onChanged,
  });

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

/// The number the whole questionnaire was for, with where it came from and
/// the one thing to understand about it: it is a starting point that moves.
class _SummaryPage extends StatelessWidget {
  const _SummaryPage({
    super.key,
    required this.target,
    required this.split,
    required this.onSplit,
  });

  final EnergyTarget target;
  final MacroSplit split;
  final ValueChanged<MacroSplit> onSplit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.xl),
      children: [
        const _PageHeading(
          title: 'Your starting point',
          body: 'Worked out on your phone from what you told us, using '
              'published equations. Your daily target, from today.',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(MananuSpacing.xl),
            child: TargetSummary(target: target),
          ),
        ),
        const SizedBox(height: MananuSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.scale_outlined,
              size: 18,
              color: MananuColors.brass,
            ),
            const SizedBox(width: MananuSpacing.md),
            Expanded(
              child: Text(
                'This will move as your weight does. Every reading off the '
                'scale recomputes it, and once there is an impedance reading '
                'it switches to your fat-free mass, which is a better basis '
                'than height and age.',
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MananuSpacing.xl),
        Text(
          'HOW YOU LIKE IT SPLIT',
          style: MananuType.label.copyWith(color: muted),
        ),
        const SizedBox(height: MananuSpacing.sm),
        MacroSplitControl(selected: split, onChanged: onSplit),
        const SizedBox(height: MananuSpacing.xl),
      ],
    );
  }
}
