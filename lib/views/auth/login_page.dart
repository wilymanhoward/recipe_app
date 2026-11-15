import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/local/seed_data.dart';
import '../../models/recipe.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/recipe_image.dart';

/// Log in, or create an account (toggled at the bottom).
///
/// One of the book's own dishes is the cover: a large photo on top on a
/// phone, beside the form when the screen is wider than it is tall.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  /// Wider than this (or in landscape), the photo sits beside the form.
  static const double sideBySideWidth = 720;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _showPassword = false;

  /// A different sample dish each time the page opens.
  late final Recipe _coverDish = (buildSeedRecipes(
    DateTime.now(),
  )..shuffle()).first;

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
    final cover = _CoverPhoto(recipe: _coverDish);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide =
              constraints.maxWidth > constraints.maxHeight ||
              constraints.maxWidth >= LoginPage.sideBySideWidth;
          final form = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _buildForm(viewModel),
          );

          if (sideBySide) {
            // The status bar icons sit over the form side here, so they
            // follow the theme instead of the photo.
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cover),
                  Expanded(
                    child: SafeArea(
                      left: false,
                      // Scrolls so the form never overflows in landscape or
                      // with the keyboard open.
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Portrait: one scrolling column, photo on top. White status bar
          // icons, because they sit on the photo.
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: math.max(180, constraints.maxHeight * 0.4),
                    child: cover,
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Center(child: form),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(AuthViewModel viewModel) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final registering = viewModel.isRegistering;
    final error = viewModel.errorMessage;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recipe Book',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            registering
                ? 'Create an account to start saving your recipes.'
                : 'Log in to cook from your saved recipes.',
            style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: 28),
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
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
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
            onFieldSubmitted: registering ? null : (_) => _submit(viewModel),
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
              validator: (value) =>
                  value == _password.text ? null : 'Passwords do not match',
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: viewModel.isBusy ? null : () => _submit(viewModel),
            child: viewModel.isBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(registering ? 'Create account' : 'Log in'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              // No side padding, so the link lines up with the text above.
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(0, 48),
              ),
              onPressed: viewModel.isBusy ? null : viewModel.toggleMode,
              child: Text(
                registering
                    ? 'Already have an account? Log in'
                    : 'New here? Create an account',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A sample dish's photo with its name in the corner.
class _CoverPhoto extends StatelessWidget {
  const _CoverPhoto({required this.recipe});

  final Recipe recipe;

  // Neutral shade so white text and status icons read on any photo.
  static const Color _clear = Color(0x00000000);
  static const Color _shade = Color(0x8C000000);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Photo of ${recipe.title}',
      image: true,
      excludeSemantics: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RecipeImage(imagePath: recipe.imagePath),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 96,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x59000000), _clear],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_clear, _shade],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: Text(
              recipe.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
