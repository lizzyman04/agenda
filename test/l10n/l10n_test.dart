import 'dart:convert';
import 'dart:io';

import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:agenda/application/shared/locale/locale_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSharedPreferences extends Mock implements SharedPreferences {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Reads an ARB file and returns a Set of its non-metadata keys.
Set<String> _arbKeys(String path) {
  final content = File(path).readAsStringSync();
  final map = jsonDecode(content) as Map<String, dynamic>;
  return map.keys.where((k) => !k.startsWith('@')).toSet();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ARB parity', () {
    test('app_en.arb and app_pt_BR.arb have identical keys', () {
      final enKeys = _arbKeys('lib/config/l10n/app_en.arb');
      final ptKeys = _arbKeys('lib/config/l10n/app_pt_BR.arb');

      expect(
        enKeys,
        equals(ptKeys),
        reason: 'EN and PT-BR ARB files must have identical translation keys. '
            'Missing from EN: ${ptKeys.difference(enKeys)}. '
            'Missing from PT-BR: ${enKeys.difference(ptKeys)}.',
      );
    });
  });

  group('LocaleCubit', () {
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
    });

    test('initial state is PT-BR when no locale stored in prefs', () {
      when(() => mockPrefs.getString('locale')).thenReturn(null);

      final cubit = LocaleCubit(mockPrefs);
      expect(cubit.state.locale, equals(const Locale('pt', 'BR')));
    });

    test('initial state is EN when prefs returns "en"', () {
      when(() => mockPrefs.getString('locale')).thenReturn('en');

      final cubit = LocaleCubit(mockPrefs);
      expect(cubit.state.locale, equals(const Locale('en')));
    });

    blocTest<LocaleCubit, LocaleState>(
      'setLocale(EN) emits LocaleState(Locale("en")) and persists to prefs',
      build: () {
        when(() => mockPrefs.getString('locale')).thenReturn(null);
        when(() => mockPrefs.setString('locale', 'en'))
            .thenAnswer((_) async => true);
        return LocaleCubit(mockPrefs);
      },
      act: (cubit) => cubit.setLocale(const Locale('en')),
      expect: () => [const LocaleState(Locale('en'))],
      verify: (_) {
        verify(() => mockPrefs.setString('locale', 'en')).called(1);
      },
    );

    blocTest<LocaleCubit, LocaleState>(
      'setLocale with unsupported locale is a no-op',
      build: () {
        when(() => mockPrefs.getString('locale')).thenReturn(null);
        return LocaleCubit(mockPrefs);
      },
      act: (cubit) => cubit.setLocale(const Locale('fr')),
      expect: () => <LocaleState>[],
    );
  });
}
