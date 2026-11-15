import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/local/seed_data.dart';
import '../../models/recipe.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/recipe_image.dart';
import '../widgets/wordmark.dart';

/// Log in, or create an account (toggled at the bottom).
///
/// The book's own dishes slide by as the cover: a large photo on top on a
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

  /// The sample dishes, in a different order each time the page opens.
  late final List<Recipe> _dishes = (buildSeedRecipes(DateTime.now())
    ..removeWhere((r) => r.imagePath == null)
    ..shuffle());

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
    final colors = Theme.of(context).colorScheme;

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
                children: [
                  Expanded(
                    // Inset and rounded so the photo reads as a framed
                    // picture of the dish, not a wall.
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: _DishCarousel(recipes: _dishes, bottomInset: 0),
                      ),
                    ),
                  ),
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

          // Portrait: the form is a sheet that overlaps the bottom of the
          // photo, so the two read as one piece. White status bar icons,
          // because they sit on the photo.
          final photoHeight = math.max(220.0, constraints.maxHeight * 0.42);
          const overlap = 28.0;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: photoHeight,
                    child: _DishCarousel(
                      recipes: _dishes,
                      bottomInset: overlap,
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(height: photoHeight - overlap),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight - photoHeight + overlap,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(overlap),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: Center(child: form),
                          ),
                        ),
                      ),
                    ],
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
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wordmark(),
          ),
          const SizedBox(height: 20),
          Text(
            registering ? 'Start your book' : 'Welcome back',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            registering
                ? 'Create an account to start saving your recipes.'
                : 'Log in to cook from your saved recipes.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
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
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: viewModel.isBusy ? null : () => _submit(viewModel),
            child: viewModel.isBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(registering ? 'Create account' : 'Log in'),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
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

/// The book's dishes, one photo at a time. Slides to the next every few
/// seconds; swiping by hand works too and restarts the wait.
class _DishCarousel extends StatefulWidget {
  const _DishCarousel({required this.recipes, required this.bottomInset});

  final List<Recipe> recipes;

  /// Space kept clear at the bottom for a sheet that overlaps the photo.
  final double bottomInset;

  @override
  State<_DishCarousel> createState() => _DishCarouselState();
}

class _DishCarouselState extends State<_DishCarousel> {
  static const Duration _hold = Duration(seconds: 4);
  static const Duration _slide = Duration(milliseconds: 700);

  // No item count: the pages repeat forever, so the last dish slides on to
  // the first in the same direction.
  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_hold, (_) {
      // Respect the system "remove animations" setting.
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _controller.nextPage(duration: _slide, curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = widget.recipes;
    final current = recipes[_page % recipes.length];
    final theme = Theme.of(context);

    return Semantics(
      label: 'Photo of ${current.title}',
      image: true,
      excludeSemantics: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (_) {
              _restartTimer();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => RecipeImage(
                imagePath: recipes[index % recipes.length].imagePath,
              ),
            ),
          ),
          // Neutral shades so white text and status icons read on any photo.
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 96,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x59000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: widget.bottomInset + 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: _slide,
                    // The switcher centers its child by default; the name
                    // belongs on the left, in line with the form's text.
                    layoutBuilder: (current, previous) => Stack(
                      alignment: AlignmentDirectional.bottomStart,
                      children: [...previous, ?current],
                    ),
                    child: Text(
                      current.title,
                      key: ValueKey(current.title),
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                for (var i = 0; i < recipes.length; i++)
                  _Dot(active: i == _page % recipes.length),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One position marker: the current dish's is longer and solid.
class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsetsDirectional.only(start: 5, bottom: 8),
      width: active ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 1 : 0.55),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
