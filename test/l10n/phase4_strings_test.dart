import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locales exercised by every assertion in this file.
const _locales = <Locale>[Locale('pt', 'BR'), Locale('en')];

/// Matches a currency symbol/code or a decimal amount such as `12,50`.
final RegExp _amountLike = RegExp(r'R\$|\$|€|£|\bMT\b|\d+[.,]\d{2}');

void main() {
  for (final locale in _locales) {
    group('Phase 4 notification strings [$locale]', () {
      // lookupAppLocalizations needs no BuildContext: this is how the
      // notification coordinator localizes text at schedule time.
      late AppLocalizations l;
      setUp(() => l = lookupAppLocalizations(locale));

      test('channel names and descriptions are non-empty', () {
        final values = <String>[
          l.notifChannelTasksName,
          l.notifChannelTasksDesc,
          l.notifChannelRecurringName,
          l.notifChannelRecurringDesc,
          l.notifChannelBriefingName,
          l.notifChannelBriefingDesc,
          l.notifChannelBudgetName,
          l.notifChannelBudgetDesc,
          l.notifChannelDebtsName,
          l.notifChannelDebtsDesc,
          l.notifChannelGoalsName,
          l.notifChannelGoalsDesc,
          l.notifChannelPaymentsName,
          l.notifChannelPaymentsDesc,
          l.notifChannelQuotesName,
          l.notifChannelQuotesDesc,
        ];
        for (final v in values) {
          expect(v.trim(), isNotEmpty);
        }
      });

      test('task reminder body carries both arguments', () {
        final body = l.notifTaskReminderBody('Pay rent', '09:30');
        expect(body, contains('Pay rent'));
        expect(body, contains('09:30'));
      });

      test('briefing title pluralises and carries the count', () {
        expect(l.notifBriefingTitle(1), isNot(equals(l.notifBriefingTitle(3))));
        expect(l.notifBriefingTitle(3), contains('3'));
        expect(l.notifBriefingTitle(1), contains('1'));
      });

      test('briefing overflow body carries the remaining count', () {
        expect(l.notifBriefingBodyMore('A, B, C', 4), contains('4'));
        expect(l.notifBriefingBodyMore('A, B, C', 4), contains('A, B, C'));
      });

      test('notification content never formats an amount', () {
        final contents = <String>[
          l.notifTaskReminderTitle,
          l.notifTaskReminderBody('Alpha', 'soon'),
          l.notifTaskDueTodayBody('Alpha'),
          l.notifRecurringTaskTitle,
          l.notifBriefingTitle(3),
          l.notifBriefingBody('Alpha, Beta'),
          l.notifBriefingBodyMore('Alpha, Beta', 2),
          l.notifBudget80Title('Food'),
          l.notifBudget80Body,
          l.notifBudget100Title('Food'),
          l.notifBudget100Body,
          l.notifDebtDueTitle,
          l.notifDebtReceiveTitle,
          l.notifDebtBody('Alpha'),
          l.notifGoalOffTrackTitle,
          l.notifGoalOffTrackBody('Alpha'),
          l.notifPaymentDueTitle,
          l.notifPaymentBody('Alpha'),
          l.notifQuoteTitle,
        ];
        for (final c in contents) {
          expect(c.trim(), isNotEmpty);
          expect(_amountLike.hasMatch(c), isFalse, reason: 'amount in "$c"');
        }
      });
    });

    group('Phase 4 settings and backup strings [$locale]', () {
      late AppLocalizations l;
      setUp(() => l = lookupAppLocalizations(locale));

      test('waiting-reminders message pluralises', () {
        expect(
          l.notifSettingsWaiting(1),
          isNot(equals(l.notifSettingsWaiting(5))),
        );
        expect(l.notifSettingsWaiting(5), contains('5'));
      });

      test('count line carries label and count', () {
        final line = l.backupCountLine('Tasks', 12);
        expect(line, contains('Tasks'));
        expect(line, contains('12'));
      });

      test('import failure carries the safety backup path', () {
        expect(
          l.backupErrorImportFailed('/data/backups/x.json'),
          contains('/data/backups/x.json'),
        );
      });

      test('date range carries both dates', () {
        final range = l.backupConfirmDateRange('2026-01-01', '2026-10-12');
        expect(range, contains('2026-01-01'));
        expect(range, contains('2026-10-12'));
      });

      test('entity labels are non-empty and pairwise distinct', () {
        final labels = <String>[
          l.backupEntityTasks,
          l.backupEntityTransactions,
          l.backupEntityCategories,
          l.backupEntityBudgets,
          l.backupEntityGoals,
          l.backupEntityDebts,
          l.backupEntityPayments,
        ];
        for (final label in labels) {
          expect(label.trim(), isNotEmpty);
        }
        expect(labels.toSet().length, labels.length);
      });

      test('import-done count resolves for 0, 1 and N', () {
        for (final n in [0, 1, 7]) {
          final text = l.backupImportDoneCount(n);
          expect(text.trim(), isNotEmpty);
          expect(text, contains('$n'));
        }
        expect(
          l.backupImportDoneCount(1),
          isNot(equals(l.backupImportDoneCount(7))),
        );
      });

      test('other plural messages resolve for 0, 1 and N', () {
        for (final n in [0, 1, 7]) {
          expect(l.backupExportCsvDone(n), contains('$n'));
          expect(l.backupConfirmDeletedIncluded(n), contains('$n'));
          expect(l.backupWarnDanglingLinks(n), contains('$n'));
        }
      });
    });
  }
}
