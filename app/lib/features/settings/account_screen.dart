import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';

/// Account.
///
/// The diary is backed up under a temporary user from the first launch, so
/// signing in is about keeping it if the phone is lost, not about getting
/// started. Apple first on iOS (guideline 4.8), Google, or a code by email.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthService auth) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = await ref.read(authServiceProvider.future);
      await action(auth);
    } on SignInCancelled {
      // Their choice; nothing to say.
    } on Object catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _friendly(Object e) {
    final text = e.toString().toLowerCase();
    if (text.contains('network') || text.contains('socket')) {
      return 'No connection. Your diary is safe on this phone; try again '
          'when you are online.';
    }
    if (text.contains('otp') ||
        text.contains('token') ||
        text.contains('code')) {
      return 'That code did not match. Codes expire after a few minutes; '
          'request a new one if it has been a while.';
    }
    return 'That did not work. Try again in a moment.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final status =
        ref.watch(accountStatusProvider).valueOrNull ?? AccountStatus.none;
    final services = ref.watch(appServicesProvider).valueOrNull;
    final hasBackend = services?.supabase != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.lg,
          MananuSpacing.sm,
          MananuSpacing.lg,
          MananuSpacing.huge,
        ),
        children: [
          _StatusCard(status: status, hasBackend: hasBackend),
          const SizedBox(height: MananuSpacing.xl),
          if (!hasBackend)
            Text(
              'This build has no backend, so there is nothing to sign in to. '
              'Everything stays on this phone.',
              style: MananuType.body.copyWith(color: muted),
            )
          else if (status.isSignedIn)
            _SignedIn(busy: _busy, onSignOut: () => _signOut(context))
          else ...[
            Text(
              status.isAnonymous
                  ? 'Sign in to keep your diary if you lose this phone or get '
                      'a new one. Nothing is re-entered: the account you '
                      'create simply becomes this one.'
                  : 'Sign in to back up your diary.',
              style: MananuType.body.copyWith(color: muted),
            ),
            const SizedBox(height: MananuSpacing.xl),
            if (AuthService.appleAvailable) ...[
              FilledButton.icon(
                onPressed:
                    _busy ? null : () => _run((a) => a.signInWithApple()),
                icon: const Icon(Icons.apple),
                label: const Text('Sign in with Apple'),
              ),
              const SizedBox(height: MananuSpacing.md),
            ],
            if (AuthService.googleAvailable) ...[
              OutlinedButton.icon(
                onPressed:
                    _busy ? null : () => _run((a) => a.signInWithGoogle()),
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: MananuSpacing.md),
            ],
            const SizedBox(height: MananuSpacing.md),
            _EmailForm(
              email: _email,
              code: _code,
              codeSent: _codeSent,
              busy: _busy,
              onSend: () => _run((a) async {
                await a.sendEmailCode(_email.text);
                if (mounted) setState(() => _codeSent = true);
              }),
              onVerify: () => _run((a) async {
                await a.verifyEmailCode(_email.text, _code.text);
                if (context.mounted) Navigator.of(context).pop();
              }),
              onChangeEmail: () => setState(() {
                _codeSent = false;
                _code.clear();
              }),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: MananuSpacing.lg),
            Text(
              _error!,
              style: MananuType.caption.copyWith(color: MananuColors.warning),
            ),
          ],
          const SizedBox(height: MananuSpacing.xxl),
          Text(
            'Mananu asks for the least it can: Apple and Google share only an '
            'identifier, and you can hide your email from us. No password to '
            'remember, nothing to reset.',
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your diary stays in your account. It is removed from this phone, '
          'so the next person to pick it up sees nothing of yours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run((auth) async {
      final services = await ref.read(appServicesProvider.future);
      // Push what is still local first, so nothing is lost with the wipe.
      try {
        await services.sync?.syncNow();
      } on Object {
        // Offline: the rows waiting to sync are lost with the wipe. The
        // dialog said the diary stays in the account, which holds for
        // everything already backed up.
      }
      final actions = await ref.read(accountActionsProvider.future);
      await auth.signOut(wipeLocal: actions.wipeLocal);
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.hasBackend});

  final AccountStatus status;
  final bool hasBackend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final String headline;
    final String detail;
    if (!hasBackend) {
      headline = 'On this phone only';
      detail = 'No account in this build.';
    } else if (status.isSignedIn) {
      headline = status.label;
      detail = 'Backed up to your account. Sign in on any phone to see it.';
    } else if (status.isAnonymous) {
      headline = 'Temporary account';
      detail = 'Backed up, but only reachable from this phone.';
    } else {
      headline = 'Not signed in';
      detail = 'Waiting for a connection to create your backup.';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xl),
        child: Row(
          children: [
            const MananuMark(height: 24),
            const SizedBox(width: MananuSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: MananuType.heading),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: MananuType.caption.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            Icon(
              status.isSignedIn
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_outlined,
              color: status.isSignedIn ? MananuColors.measured : muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.busy, required this.onSignOut});

  final bool busy;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onSignOut,
      child: const Text('Sign out of this phone'),
    );
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.email,
    required this.code,
    required this.codeSent,
    required this.busy,
    required this.onSend,
    required this.onVerify,
    required this.onChangeEmail,
  });

  final TextEditingController email;
  final TextEditingController code;
  final bool codeSent;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onVerify;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Or use your email', style: MananuType.heading),
            const SizedBox(height: MananuSpacing.xs),
            Text(
              codeSent
                  ? 'We sent a six-digit code to ${email.text.trim()}.'
                  : 'We will send a code. No password.',
              style: MananuType.caption.copyWith(color: muted),
            ),
            const SizedBox(height: MananuSpacing.md),
            if (!codeSent) ...[
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: MananuSpacing.md),
              FilledButton(
                onPressed: busy || !email.text.contains('@') ? null : onSend,
                child: const Text('Send code'),
              ),
            ] else ...[
              TextField(
                controller: code,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onVerify(),
                decoration: const InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: MananuSpacing.md),
              FilledButton(
                onPressed: busy ? null : onVerify,
                child: const Text('Sign in'),
              ),
              TextButton(
                onPressed: busy ? null : onChangeEmail,
                child: const Text('Use a different email'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
