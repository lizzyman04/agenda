import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/generated/l10n/app_localizations_pt.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_answers.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_actions.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_clarify.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_prioritize.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Walks the GTD decision tree with no widgets involved.
///
/// This is the payoff of splitting the tree out of the sheet: the questions
/// and the state transitions they cause are plain functions, so they can be
/// exercised directly instead of by tapping through a bottom sheet.
void main() {
  late AppLocalizations l10n;
  late GtdAnswers answers;
  late TextEditingController titleCtrl;
  late TextEditingController delegateCtrl;
  late List<GtdNode> pushed;
  late List<String> snackbars;
  late int abandonCount;

  GtdTreeContext ctx() => GtdTreeContext(
        l10n: l10n,
        answers: answers,
        titleCtrl: titleCtrl,
        delegateCtrl: delegateCtrl,
        push: pushed.add,
        endWithSnackbar: snackbars.add,
        pickCustomDate: () {},
        abandon: () => abandonCount++,
      );

  /// Resolves a node through whichever half of the tree owns it.
  GtdNodeSpec? specFor(GtdNode node) =>
      clarifySpec(node, ctx()) ?? prioritizeSpec(node, ctx());

  /// Taps the option at [index] of an option node.
  void tap(GtdNode node, int index) {
    final spec = specFor(node)! as GtdOptionSpec;
    spec.options[index].$3();
  }

  setUp(() {
    l10n = AppLocalizationsPt();
    answers = GtdAnswers();
    titleCtrl = TextEditingController();
    delegateCtrl = TextEditingController();
    pushed = [];
    snackbars = [];
    abandonCount = 0;
  });

  tearDown(() {
    titleCtrl.dispose();
    delegateCtrl.dispose();
  });

  group('every node resolves', () {
    test('no node in the enum is unhandled by either half', () {
      for (final node in GtdNode.values) {
        expect(specFor(node), isNotNull, reason: '$node has no spec');
      }
    });

    test('the two halves never both claim a node', () {
      for (final node in GtdNode.values) {
        final inClarify = clarifySpec(node, ctx()) != null;
        final inPrioritize = prioritizeSpec(node, ctx()) != null;
        expect(
          inClarify && inPrioritize,
          isFalse,
          reason: '$node is claimed by both halves',
        );
      }
    });
  });

  group('q1 title', () {
    test('does not advance while the title is blank', () {
      final spec = specFor(GtdNode.q1Title)! as GtdTextSpec;
      titleCtrl.text = '   ';
      spec.onNext();
      expect(pushed, isEmpty);
    });

    test('advances and infers a context from the title', () {
      final spec = specFor(GtdNode.q1Title)! as GtdTextSpec;
      titleCtrl.text = 'Comprar leite';
      spec.onNext();
      expect(pushed, [GtdNode.q2Actionable]);
      expect(answers.gtdContext, '@compras');
    });

    test('leaves the context unset when nothing matches', () {
      final spec = specFor(GtdNode.q1Title)! as GtdTextSpec;
      titleCtrl.text = 'Reunião';
      spec.onNext();
      expect(answers.gtdContext, isNull);
    });
  });

  group('delegation', () {
    test('records who the task is waiting on', () {
      final spec = specFor(GtdNode.q3bDelegateName)! as GtdTextSpec;
      delegateCtrl.text = 'Joao';
      spec.onNext();
      expect(answers.waitingFor, 'Joao');
      expect(pushed, [GtdNode.q3cFollowUp]);
    });

    test('refuses to advance without a name', () {
      final spec = specFor(GtdNode.q3bDelegateName)! as GtdTextSpec;
      delegateCtrl.text = '';
      spec.onNext();
      expect(answers.waitingFor, isNull);
      expect(pushed, isEmpty);
    });
  });

  group('prioritisation', () {
    test('"someday" ends the flow with a message rather than a task', () {
      tap(GtdNode.q2bWhyAdd, 0);
      expect(snackbars, hasLength(1));
      expect(answers.priority, Priority.low);
      expect(answers.gtdContext, 'someday');
      expect(pushed, isEmpty);
    });

    test('answering "important" sets the flag and moves to the deadline', () {
      tap(GtdNode.q5Important, 0);
      expect(answers.isImportant, isTrue);
      expect(pushed, [GtdNode.q6Deadline]);
    });

    test('"someone is asking" raises priority and marks urgent', () {
      tap(GtdNode.q5bWhyKeep, 1);
      expect(answers.isUrgent, isTrue);
      expect(answers.priority, Priority.high);
    });

    test('demotion never overrides an explicit priority', () {
      answers.priority = Priority.high;
      tap(GtdNode.q5bWhyKeep, 0); // "obligation" — demotes only if unset
      expect(answers.priority, Priority.high);
    });

    test('cancelling a task abandons the guide', () {
      tap(GtdNode.q5bWhyKeep, 3);
      expect(abandonCount, 1);
      expect(pushed, isEmpty);
    });
  });

  group('deadline', () {
    test('today marks the task urgent and dated', () {
      tap(GtdNode.q6Deadline, 0);
      expect(answers.dueDate, GtdAnswers.today());
      expect(answers.isUrgent, isTrue);
      expect(pushed, [GtdNode.q7Impact]);
    });

    test('no deadline branches to the reason question', () {
      tap(GtdNode.q6Deadline, 5);
      expect(answers.dueDate, isNull);
      expect(pushed, [GtdNode.q6bNoDeadlineReason]);
    });
  });

  group('impact', () {
    test('very negative impact is urgent only when a deadline exists', () {
      tap(GtdNode.q7Impact, 0);
      expect(answers.priority, Priority.urgent);
      expect(answers.isImportant, isTrue);
      expect(answers.isUrgent, isFalse, reason: 'no deadline was set');

      answers = GtdAnswers()..dueDate = DateTime(2026, 8, 11);
      tap(GtdNode.q7Impact, 0);
      expect(answers.isUrgent, isTrue);
    });

    test('no impact branches to the keep-anyway question', () {
      tap(GtdNode.q7Impact, 5);
      expect(pushed, [GtdNode.q7bWhyKeepNoImpact]);
    });
  });

  group('result', () {
    test('carries every accumulated answer', () {
      answers
        ..priority = Priority.high
        ..isImportant = true
        ..isUrgent = true
        ..dueDate = DateTime(2026, 8, 11)
        ..waitingFor = 'Joao'
        ..gtdContext = '@trabalho'
        ..description = 'nota';

      final result = answers.toResult('Enviar proposta');

      expect(result.title, 'Enviar proposta');
      expect(result.priority, Priority.high);
      expect(result.isImportant, isTrue);
      expect(result.isUrgent, isTrue);
      expect(result.dueDate, DateTime(2026, 8, 11));
      expect(result.waitingFor, 'Joao');
      expect(result.gtdContext, '@trabalho');
      expect(result.description, 'nota');
    });
  });

  group('progress', () {
    test('main-path steps advance the indicator', () {
      expect(gtdStepIndex([GtdNode.q1Title]), 0);
      expect(
        gtdStepIndex([GtdNode.q1Title, GtdNode.q2Actionable]),
        1,
      );
    });

    test('a follow-up branch does not move the indicator backwards', () {
      final history = [
        GtdNode.q1Title,
        GtdNode.q2Actionable,
        GtdNode.q2bWhyAdd,
      ];
      expect(gtdStepIndex(history), 1, reason: 'q2b is off the main path');
    });
  });
}
