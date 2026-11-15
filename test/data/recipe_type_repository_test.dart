import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/data/repositories/recipe_type_repository.dart';

/// Serves one asset and counts how often it was read.
class _CountingBundle extends CachingAssetBundle {
  _CountingBundle(this.json);

  final String json;
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    reads++;
    return ByteData.sublistView(Uint8List.fromList(json.codeUnits));
  }
}

void main() {
  test('reads the bundled file once and reuses it', () async {
    final bundle = _CountingBundle(
      '{"recipeTypes":[{"id":1,"name":"Breakfast"},{"id":2,"name":"Lunch"}]}',
    );
    final repository = AssetRecipeTypeRepository(bundle);

    final first = await repository.getAll();
    final second = await repository.getAll();

    expect(first.map((t) => t.name), ['Breakfast', 'Lunch']);
    expect(identical(first, second), isTrue);
    expect(bundle.reads, 1);
  });

  test('the bundled list never changes, so it announces nothing', () async {
    final repository = AssetRecipeTypeRepository(
      _CountingBundle('{"recipeTypes":[{"id":1,"name":"Breakfast"}]}'),
    );

    expect(await repository.refreshed.isEmpty, isTrue);
  });
}
