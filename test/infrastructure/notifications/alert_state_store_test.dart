import 'package:agenda/infrastructure/notifications/prefs/alert_state_store_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AlertStateStoreImpl> _store() async {
  SharedPreferences.setMockInitialValues({});
  return AlertStateStoreImpl(await SharedPreferences.getInstance());
}

void main() {
  test('add is idempotent', () async {
    final store = await _store();
    await store.add('goal:3:2026-W42');
    await store.add('goal:3:2026-W42');
    await store.addAll(['goal:3:2026-W42', 'budget:7:80']);

    expect(await store.keys(), {'goal:3:2026-W42', 'budget:7:80'});
    expect(await store.contains('budget:7:80'), isTrue);
    expect(await store.contains('missing'), isFalse);
  });

  test('removeWhere drops keys by prefix only', () async {
    final store = await _store();
    await store.addAll(['goal:1:a', 'goal:2:b', 'budget:1:80']);

    await store.removeWhere((key) => key.startsWith('goal:'));

    expect(await store.keys(), {'budget:1:80'});
  });

  test('clear empties the store', () async {
    final store = await _store();
    await store.addAll(['a', 'b']);

    await store.clear();

    expect(await store.keys(), isEmpty);
  });

  test('values persist across a new instance', () async {
    final first = await _store();
    await first.addAll(['a', 'b']);

    final second = AlertStateStoreImpl(await SharedPreferences.getInstance());

    expect(await second.keys(), {'a', 'b'});
  });
}
