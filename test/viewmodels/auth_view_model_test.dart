import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/data/repositories/auth_repository.dart';
import 'package:recipe_app/models/user.dart';
import 'package:recipe_app/viewmodels/auth_view_model.dart';

import '../helpers/fakes.dart';

/// Fails every call, like a database error.
class _BrokenAuthRepository extends FakeAuthRepository {
  @override
  Future<User> login(String username, String password) =>
      Future.error(StateError('disk full'));
}

void main() {
  Future<AuthViewModel> create(AuthRepository repository) async {
    final viewModel = AuthViewModel(authRepository: repository);
    await pumpEventQueue();
    return viewModel;
  }

  test('starts as checking, then signed out with no session', () async {
    final viewModel = AuthViewModel(authRepository: FakeAuthRepository());
    expect(viewModel.status, AuthStatus.checking);

    await pumpEventQueue();
    expect(viewModel.status, AuthStatus.signedOut);
  });

  test('a saved session signs straight in', () async {
    final viewModel = await create(
      FakeAuthRepository(sessionUser: FakeAuthRepository.cook),
    );

    expect(viewModel.status, AuthStatus.signedIn);
    expect(viewModel.user?.username, 'cook');
  });

  test('wrong details show the message and stay signed out', () async {
    final viewModel = await create(FakeAuthRepository());

    await viewModel.submit('cook', 'nope');

    expect(viewModel.status, AuthStatus.signedOut);
    expect(viewModel.errorMessage, 'Wrong username or password.');
    expect(viewModel.isBusy, isFalse);
  });

  test('an unexpected error shows a generic message', () async {
    final viewModel = await create(_BrokenAuthRepository());

    await viewModel.submit('cook', 'secret1');

    expect(viewModel.errorMessage, 'Something went wrong. Please try again.');
  });

  test('register mode uses the register call and the length rule', () async {
    final viewModel = await create(FakeAuthRepository());

    expect(viewModel.validatePassword('abc'), isNull, reason: 'login mode');
    viewModel.toggleMode();
    expect(viewModel.validatePassword('abc'), isNotNull);
    expect(viewModel.validatePassword('abcdef'), isNull);

    await viewModel.submit('baker', 'secret1');
    expect(viewModel.status, AuthStatus.signedIn);
    expect(viewModel.user?.username, 'baker');
  });

  test('logout signs out and returns to login mode', () async {
    final viewModel =
        await create(FakeAuthRepository(sessionUser: FakeAuthRepository.cook))
          ..toggleMode();

    await viewModel.logout();

    expect(viewModel.status, AuthStatus.signedOut);
    expect(viewModel.user, isNull);
    expect(viewModel.isRegistering, isFalse);
  });
}
