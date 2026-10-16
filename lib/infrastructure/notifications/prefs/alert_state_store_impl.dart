import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/domain/notifications/alert_state_store.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [AlertStateStore] over [SharedPreferences].
///
/// Keys live as a de-duplicated string list under
/// [StorageKeys.notifAlertState]. Adding a stored key is a no-op.
@LazySingleton(as: AlertStateStore)
class AlertStateStoreImpl implements AlertStateStore {
  AlertStateStoreImpl(this._store);

  final SharedPreferences _store;

  Set<String> _read() =>
      (_store.getStringList(StorageKeys.notifAlertState) ?? const <String>[])
          .toSet();

  Future<void> _write(Set<String> keys) =>
      _store.setStringList(StorageKeys.notifAlertState, keys.toList()..sort());

  @override
  Future<Set<String>> keys() async => _read();

  @override
  Future<bool> contains(String key) async => _read().contains(key);

  @override
  Future<void> add(String key) => addAll([key]);

  @override
  Future<void> addAll(Iterable<String> keys) async {
    final current = _read();
    if (current.containsAll(keys)) return;
    await _write(current..addAll(keys));
  }

  @override
  Future<void> removeWhere(bool Function(String key) test) async {
    final current = _read();
    final before = current.length;
    current.removeWhere(test);
    if (current.length != before) await _write(current);
  }

  @override
  Future<void> clear() async {
    await _store.remove(StorageKeys.notifAlertState);
  }
}
