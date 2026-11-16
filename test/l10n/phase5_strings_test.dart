import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locales exercised by every assertion in this file.
const _ptBr = Locale('pt', 'BR');
const _en = Locale('en');
const _locales = <Locale>[_ptBr, _en];

/// D-12 headline, exact per locale (no trailing period).
final _headline = <Locale, String>{
  _ptBr: 'Seus dados nunca saem deste aparelho',
  _en: 'Your data never leaves this device',
};

/// Every new Phase 5 string that takes no argument (plan 05-01, Task 2).
List<String> _plainStrings(AppLocalizations l) => <String>[
  l.privacyGetStarted,
  l.pinSetupTitle,
  l.privacyIntro,
  l.privacyBulletOffline,
  l.privacyBulletNoTracking,
  l.privacyBulletBackup,
  l.privacyBulletPin,
  l.settingsSectionGeneral,
  l.settingsSectionSecurity,
  l.settingsSectionNotifications,
  l.settingsSectionData,
  l.settingsSectionAbout,
  l.settingsLanguageDialogTitle,
  l.languageNamePtBr,
  l.languageNameEn,
  l.lockPinToggle,
  l.lockPinToggleDesc,
  l.lockChangePin,
  l.lockBiometricToggle,
  l.lockBiometricToggleDesc,
  l.lockBiometricNotEnrolled,
  l.lockTimeoutLabel,
  l.lockTimeoutDialogTitle,
  l.lockTimeoutImmediate,
  l.lockTimeout30s,
  l.lockTimeout1m,
  l.lockTimeout5m,
  l.lockTimeout15m,
  l.settingsNotificationsDesc,
  l.settingsDataDesc,
  l.settingsPrivacyLabel,
  l.settingsVersionLabel,
  l.lockEnterPinTitle,
  l.pinCreatePrompt,
  l.pinConfirmPrompt,
  l.pinCurrentPrompt,
  l.lockForgotPin,
  l.lockBiometricReason,
  l.lockForgotReason,
  l.lockDeleteDigit,
  l.pinEnabledSnack,
  l.pinChangedSnack,
  l.pinDisabledSnack,
  l.tasksEmptyBody,
  l.tasksEmptyCta,
  l.tasksSearchEmptyTitle,
  l.gtdEmptyBody,
  l.pinMismatch,
  l.lockErrorGeneric,
  l.lockForgotUnavailableTitle,
  l.lockForgotUnavailableBody,
  l.lockGotIt,
  l.pinNoDeviceLockTitle,
  l.pinNoDeviceLockBody,
  l.pinNoDeviceLockContinue,
  l.pinDisableTitle,
  l.pinDisableBody,
  l.pinDisableConfirm,
  l.lockBiometricSheetTitle,
  l.lockBiometricSheetHint,
  l.lockUsePin,
];

/// Every new Phase 5 string, with sample arguments for the parameterised ones.
List<String> _allStrings(AppLocalizations l) => <String>[
  ..._plainStrings(l),
  l.privacyStatement,
  l.lockDigitsEntered(2),
  l.tasksSearchEmptyBody('xyz'),
  l.lockWrongPin(1),
  l.lockWrongPin(3),
  l.lockCooldown('0:30'),
];

void main() {
  for (final locale in _locales) {
    group('Phase 5 strings [$locale]', () {
      late AppLocalizations l;
      setUp(() => l = lookupAppLocalizations(locale));

      test('privacyStatement is the D-12 headline exactly', () {
        expect(l.privacyStatement, _headline[locale]);
      });

      test('every new getter is non-empty', () {
        final values = _allStrings(l);
        // 61 plain getters + privacyStatement + 5 parameterised samples.
        expect(values, hasLength(67));
        for (final v in values) {
          expect(v.trim(), isNotEmpty);
        }
      });

      test('lockWrongPin pluralises and carries the count', () {
        expect(l.lockWrongPin(1), isNot(equals(l.lockWrongPin(3))));
        expect(l.lockWrongPin(1), contains('1'));
        expect(l.lockWrongPin(3), contains('3'));
        expect(l.lockWrongPin(2), contains('2'));
        expect(l.lockWrongPin(4), contains('4'));
        expect(
          l.lockWrongPin(2),
          equals(l.lockWrongPin(3).replaceAll('3', '2')),
        );
      });

      test('placeholders reach the text', () {
        expect(l.lockCooldown('0:30'), contains('0:30'));
        expect(l.lockDigitsEntered(2), contains('2'));
        expect(l.tasksSearchEmptyBody('xyz'), contains('xyz'));
      });

      test('no new string claims the data is encrypted (T-05-03)', () {
        final pattern = RegExp('criptograf|encrypt', caseSensitive: false);
        for (final v in _allStrings(l)) {
          expect(v, isNot(matches(pattern)), reason: v);
        }
      });
    });
  }

  group('Phase 5 cross-locale rules', () {
    final pt = lookupAppLocalizations(_ptBr);
    final en = lookupAppLocalizations(_en);

    test('lockWrongPin zero-one-many copy, exact per locale', () {
      expect(pt.lockWrongPin(1), 'PIN incorreto. Resta 1 tentativa.');
      expect(pt.lockWrongPin(2), 'PIN incorreto. Restam 2 tentativas.');
      expect(pt.lockWrongPin(4), 'PIN incorreto. Restam 4 tentativas.');
      expect(en.lockWrongPin(1), 'Wrong PIN. 1 attempt left.');
      expect(en.lockWrongPin(2), 'Wrong PIN. 2 attempts left.');
      expect(en.lockWrongPin(4), 'Wrong PIN. 4 attempts left.');
    });

    test('language endonyms are identical in both locales (D-11)', () {
      expect(pt.languageNamePtBr, 'Português (Brasil)');
      expect(en.languageNamePtBr, pt.languageNamePtBr);
      expect(pt.languageNameEn, 'English');
      expect(en.languageNameEn, pt.languageNameEn);
    });

    test('PT-BR says "aparelho", never "dispositivo"', () {
      for (final v in _allStrings(pt)) {
        expect(v.toLowerCase(), isNot(contains('dispositivo')), reason: v);
      }
    });

    test('the four privacy bullets carry the D-13 content', () {
      expect(pt.privacyBulletOffline, contains('sem internet'));
      expect(pt.privacyBulletOffline, contains('conta'));
      expect(pt.privacyBulletNoTracking, contains('análises'));
      expect(pt.privacyBulletNoTracking, contains('relatórios de erro'));
      expect(pt.privacyBulletBackup, contains('nuvem'));
      expect(pt.privacyBulletBackup, contains('backup JSON'));
      expect(pt.privacyBulletPin, contains('PIN opcional'));
      expect(en.privacyBulletOffline, contains('offline'));
      expect(en.privacyBulletOffline, contains('account'));
      expect(en.privacyBulletNoTracking, contains('analytics'));
      expect(en.privacyBulletNoTracking, contains('crash reports'));
      expect(en.privacyBulletBackup, contains('no cloud backup'));
      expect(en.privacyBulletBackup, contains('JSON backup'));
      expect(en.privacyBulletPin, contains('optional PIN'));
    });
  });
}
