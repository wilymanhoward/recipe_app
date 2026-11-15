import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/di/locator.dart';
import 'package:recipe_app/data/repositories/recipe_repository.dart';
import 'package:recipe_app/data/repositories/recipe_type_repository.dart';
import 'package:recipe_app/viewmodels/auth_view_model.dart';
import 'package:recipe_app/viewmodels/theme_view_model.dart';
import 'package:recipe_app/views/auth/login_page.dart';
import 'package:recipe_app/views/home/home_shell.dart';

import '../helpers/fakes.dart';

void main() {
  setUp(() {
    locator
      ..registerSingleton<RecipeRepository>(
        FakeRecipeRepository([testRecipe(isFavourite: false)]),
      )
      ..registerSingleton<RecipeTypeRepository>(FakeRecipeTypeRepository());
  });

  tearDown(locator.reset);

  /// The same login gate as the app, without the real database.
  Future<void> pumpApp(WidgetTester tester, FakeAuthRepository auth) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthViewModel(authRepository: auth),
          ),
          // The Profile tab reads the theme choice.
          ChangeNotifierProvider(
            create: (_) => ThemeViewModel(settings: FakeSettingsRepository()),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) =>
                switch (context.watch<AuthViewModel>().status) {
                  AuthStatus.signedIn => const HomeShell(),
                  _ => const LoginPage(),
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> logIn(WidgetTester tester, String user, String password) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      user,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      password,
    );
    final button = find.widgetWithText(FilledButton, 'Log in');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('empty fields show validation messages', (tester) async {
    await pumpApp(tester, FakeAuthRepository());

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Use at least 3 characters'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('a wrong password shows an error and stays on login', (
    tester,
  ) async {
    await pumpApp(tester, FakeAuthRepository());

    await logIn(tester, 'cook', 'nope');

    expect(find.text('Wrong username or password.'), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });

  testWidgets('logging in opens the app, logging out returns', (tester) async {
    await pumpApp(tester, FakeAuthRepository());

    await logIn(tester, 'cook', 'secret1');
    expect(find.byType(HomeShell), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('cook'), findsOneWidget);
    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    // Asks first; confirming in the dialog is what logs out.
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('cancelling the log out dialog keeps the session', (
    tester,
  ) async {
    await pumpApp(tester, FakeAuthRepository());
    await logIn(tester, 'cook', 'secret1');
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('a saved session skips the login page', (tester) async {
    await pumpApp(
      tester,
      FakeAuthRepository(sessionUser: FakeAuthRepository.cook),
    );

    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('register asks to confirm the password', (tester) async {
    await pumpApp(tester, FakeAuthRepository());
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'baker',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'secret2',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('favourites tab starts empty and fills from the heart', (
    tester,
  ) async {
    await pumpApp(
      tester,
      FakeAuthRepository(sessionUser: FakeAuthRepository.cook),
    );
    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No favourites yet.'), findsOneWidget);

    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to favourites'));
    await tester.pumpAndSettle();

    final repository = locator<RecipeRepository>() as FakeRecipeRepository;
    expect(repository.recipes.single.isFavourite, isTrue);
  });

  for (final (size, navigation) in const [
    (Size(320, 568), NavigationBar),
    (Size(568, 320), NavigationRail),
    (Size(1024, 768), NavigationRail),
  ]) {
    testWidgets('uses $navigation at $size without overflow', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpApp(tester, FakeAuthRepository());
      expect(tester.takeException(), isNull, reason: 'login page');

      await logIn(tester, 'cook', 'secret1');

      expect(find.byType(navigation), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'home');
    });
  }
}
