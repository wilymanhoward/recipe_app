import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/data/local/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('saves, reads back and clears the user id', () async {
    final store = SecureSessionStore();
    expect(await store.readUserId(), isNull);

    await store.saveUserId(42);
    expect(await store.readUserId(), 42);

    await store.clear();
    expect(await store.readUserId(), isNull);
  });

  test('a corrupted value counts as logged out', () async {
    FlutterSecureStorage.setMockInitialValues({'session_user_id': 'oops'});

    expect(await SecureSessionStore().readUserId(), isNull);
  });
}
