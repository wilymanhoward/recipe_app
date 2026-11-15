import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_view_model.dart';

/// Log in, or create an account (toggled at the bottom).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await viewModel.submit(_username.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final registering = viewModel.isRegistering;
    final error = viewModel.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: Center(
          // Scrolls so the form never overflows on small screens, in
          // landscape, or with the keyboard open.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 56,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Recipe Book',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      registering
                          ? 'Create an account to start your recipe book.'
                          : 'Welcome back! Log in to see your recipes.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: viewModel.validateUsername,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Hide password'
                              : 'Show password',
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      autofillHints: [
                        if (registering)
                          AutofillHints.newPassword
                        else
                          AutofillHints.password,
                      ],
                      textInputAction: registering
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: registering
                          ? null
                          : (_) => _submit(viewModel),
                      validator: viewModel.validatePassword,
                    ),
                    if (registering) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        obscureText: !_showPassword,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(viewModel),
                        validator: (value) => value == _password.text
                            ? null
                            : 'Passwords do not match',
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: viewModel.isBusy
                          ? null
                          : () => _submit(viewModel),
                      child: viewModel.isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(registering ? 'Create account' : 'Log in'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: viewModel.isBusy ? null : viewModel.toggleMode,
                      child: Text(
                        registering
                            ? 'Already have an account? Log in'
                            : 'New here? Create an account',
                      ),
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
