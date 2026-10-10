import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/slotly_logo.dart';
import '../../../data/seed/demo_accounts.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import 'session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.session,
    this.accounts = demoAccounts,
  });

  final SessionController session;

  final List<DemoAccount> accounts;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await widget.session.signIn(_login.text, _password.text);
    } on InvalidCredentialsException {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.signInInvalid;
        _isSubmitting = false;
      });
    }
  }

  void _fill(DemoAccount account) {
    setState(() {
      _login.text = account.user.login;
      _password.text = account.password;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.signInTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.l),
          child: ResponsiveCenter(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SlotlyLogo(size: 48),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      AppStrings.signInSubtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      key: const ValueKey('login-field'),
                      controller: _login,
                      enabled: !_isSubmitting,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: AppStrings.signInLogin,
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? AppStrings.signInLoginRequired
                          : null,
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextFormField(
                      key: const ValueKey('password-field'),
                      controller: _password,
                      focusNode: _passwordFocus,
                      enabled: !_isSubmitting,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: AppStrings.signInPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? AppStrings.signInShowPassword
                              : AppStrings.signInHidePassword,
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (value) => (value ?? '').isEmpty
                          ? AppStrings.signInPasswordRequired
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: AppSpacing.m),
                      Semantics(
                        liveRegion: true,
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.l),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Text(AppStrings.signInSubmit),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _DemoAccounts(
                      accounts: widget.accounts,
                      onSelected: _isSubmitting ? null : _fill,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.accounts, required this.onSelected});

  final List<DemoAccount> accounts;
  final ValueChanged<DemoAccount>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                0,
              ),
              child: Text(
                AppStrings.signInDemoAccounts,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.xs,
                AppSpacing.l,
                AppSpacing.s,
              ),
              child: Text(AppStrings.signInDemoNotice, style: muted),
            ),
            for (final account in accounts.take(4))
              ListTile(
                leading: Icon(
                  account.user.isOwner
                      ? Icons.storefront_outlined
                      : Icons.person_outline,
                ),
                title: Text(
                  '${account.user.displayName} · '
                  '${account.user.role == UserRole.owner ? AppStrings.roleOwner : AppStrings.roleClient}',
                ),
                subtitle: Text(
                  '${account.user.login} / ${account.password}\n'
                  '${account.scenario}',
                ),
                isThreeLine: true,
                onTap: onSelected == null ? null : () => onSelected!(account),
              ),
          ],
        ),
      ),
    );
  }
}
