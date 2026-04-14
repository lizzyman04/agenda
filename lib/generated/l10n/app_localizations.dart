import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt', 'BR'),
    Locale('en'),
    Locale('pt'),
  ];

  /// Nome da aplicação exibido na barra de título
  ///
  /// In pt_BR, this message translates to:
  /// **'AGENDA'**
  String get appName;

  /// Título da tela de configurações
  ///
  /// In pt_BR, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// Rótulo para o seletor de idioma nas configurações
  ///
  /// In pt_BR, this message translates to:
  /// **'Idioma'**
  String get languageLabel;

  /// Declaração de privacidade exibida no primeiro lançamento (UX-03)
  ///
  /// In pt_BR, this message translates to:
  /// **'Os seus dados nunca saem deste dispositivo.'**
  String get privacyStatement;

  /// Título genérico para estados vazios (UX-04)
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum item ainda'**
  String get emptyStateTitle;

  /// Ação genérica para estados vazios (UX-04)
  ///
  /// In pt_BR, this message translates to:
  /// **'Toque para adicionar'**
  String get emptyStateAction;

  /// Título da tela de lista de tarefas
  ///
  /// In pt_BR, this message translates to:
  /// **'Tarefas'**
  String get tasksScreenTitle;

  /// Texto de estado vazio na tela de lista de tarefas
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma tarefa'**
  String get noTasks;

  /// Conteúdo da SnackBar após exclusão suave
  ///
  /// In pt_BR, this message translates to:
  /// **'Tarefa excluída'**
  String get taskDeleted;

  /// Rótulo da ação de desfazer na SnackBar
  ///
  /// In pt_BR, this message translates to:
  /// **'Desfazer'**
  String get undo;

  /// Texto de estado vazio dentro de um quadrante
  ///
  /// In pt_BR, this message translates to:
  /// **'Vazia'**
  String get quadrantEmpty;

  /// Texto do banner de aviso quando um slot 1-3-5 está acima da capacidade
  ///
  /// In pt_BR, this message translates to:
  /// **'Limite excedido'**
  String get slotLimitExceeded;

  /// Banner de aviso global na tela do planejador diário
  ///
  /// In pt_BR, this message translates to:
  /// **'Limite de slot excedido'**
  String get slotLimitWarning;

  /// Rótulo da ação de adicionar na seção de slot
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar'**
  String get addTask;

  /// Rótulo para o slot de tarefa grande no planejador 1-3-5
  ///
  /// In pt_BR, this message translates to:
  /// **'1 Grande Tarefa'**
  String get bigTask;

  /// Rótulo para o slot de tarefas médias no planejador 1-3-5
  ///
  /// In pt_BR, this message translates to:
  /// **'3 Tarefas Médias'**
  String get mediumTasks;

  /// Rótulo para o slot de tarefas pequenas no planejador 1-3-5
  ///
  /// In pt_BR, this message translates to:
  /// **'5 Tarefas Pequenas'**
  String get smallTasks;

  /// Título da AppBar para a tela do planejador diário
  ///
  /// In pt_BR, this message translates to:
  /// **'Planejamento 1-3-5'**
  String get dayPlannerTitle;

  /// Título da AppBar para a tela do quadro Eisenhower
  ///
  /// In pt_BR, this message translates to:
  /// **'Matriz Eisenhower'**
  String get eisenhowerTitle;

  /// Rótulo do quadrante Q1 — Urgente + Importante
  ///
  /// In pt_BR, this message translates to:
  /// **'Fazer Agora'**
  String get eisenhowerDoNow;

  /// Rótulo do quadrante Q2 — Não urgente + Importante
  ///
  /// In pt_BR, this message translates to:
  /// **'Agendar'**
  String get eisenhowerSchedule;

  /// Rótulo do quadrante Q3 — Urgente + Não importante
  ///
  /// In pt_BR, this message translates to:
  /// **'Delegar'**
  String get eisenhowerDelegate;

  /// Rótulo do quadrante Q4 — Não urgente + Não importante
  ///
  /// In pt_BR, this message translates to:
  /// **'Eliminar'**
  String get eisenhowerEliminate;

  /// Título da AppBar ao criar uma nova tarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Nova Tarefa'**
  String get taskFormTitleCreate;

  /// Título da AppBar ao editar uma tarefa existente
  ///
  /// In pt_BR, this message translates to:
  /// **'Editar Tarefa'**
  String get taskFormTitleEdit;

  /// Rótulo do campo de título no formulário de tarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Título'**
  String get fieldTitle;

  /// Erro de validação quando o título está vazio
  ///
  /// In pt_BR, this message translates to:
  /// **'Título é obrigatório'**
  String get fieldTitleRequired;

  /// Rótulo do campo de descrição
  ///
  /// In pt_BR, this message translates to:
  /// **'Descrição'**
  String get fieldDescription;

  /// Rótulo do dropdown de prioridade
  ///
  /// In pt_BR, this message translates to:
  /// **'Prioridade'**
  String get fieldPriority;

  /// Rótulo do campo de data de vencimento
  ///
  /// In pt_BR, this message translates to:
  /// **'Prazo'**
  String get fieldDueDate;

  /// Rótulo do campo de hora de vencimento
  ///
  /// In pt_BR, this message translates to:
  /// **'Horário'**
  String get fieldDueTime;

  /// Placeholder quando nenhuma data de vencimento está definida
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem prazo'**
  String get noDueDate;

  /// Placeholder quando nenhum horário está definido
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem hora'**
  String get noDueTime;

  /// Rótulo do switch isUrgent
  ///
  /// In pt_BR, this message translates to:
  /// **'Urgente'**
  String get fieldUrgent;

  /// Rótulo do switch isImportant
  ///
  /// In pt_BR, this message translates to:
  /// **'Importante'**
  String get fieldImportant;

  /// Rótulo do botão segmentado de categoria de tamanho
  ///
  /// In pt_BR, this message translates to:
  /// **'Tamanho'**
  String get fieldSize;

  /// Rótulo da checkbox isNextAction
  ///
  /// In pt_BR, this message translates to:
  /// **'Próxima ação'**
  String get fieldNextAction;

  /// Rótulo do campo de contexto GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Contexto GTD'**
  String get fieldGtdContext;

  /// Rótulo do campo de aguardando
  ///
  /// In pt_BR, this message translates to:
  /// **'Aguardando'**
  String get fieldWaitingFor;

  /// Rótulo do campo de valor
  ///
  /// In pt_BR, this message translates to:
  /// **'Valor'**
  String get fieldAmount;

  /// Rótulo do campo de moeda
  ///
  /// In pt_BR, this message translates to:
  /// **'Moeda'**
  String get fieldCurrency;

  /// Rótulo do botão salvar
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar'**
  String get saveButton;

  /// Título padrão da AppBar para a tela de projeto
  ///
  /// In pt_BR, this message translates to:
  /// **'Projeto'**
  String get projectScreenTitle;

  /// Rótulo de progresso de conclusão de subtarefas
  ///
  /// In pt_BR, this message translates to:
  /// **'{completed}/{total} subtarefas'**
  String subtasksProgress(int completed, int total);

  /// Rótulo para o FAB/botão de adicionar subtarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar subtarefa'**
  String get addSubtask;

  /// Texto de dica no campo de texto da folha de adicionar subtarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Título da subtarefa'**
  String get subtaskTitleHint;

  /// Prioridade: baixa
  ///
  /// In pt_BR, this message translates to:
  /// **'Baixa'**
  String get priorityLow;

  /// Prioridade: média
  ///
  /// In pt_BR, this message translates to:
  /// **'Média'**
  String get priorityMedium;

  /// Prioridade: alta
  ///
  /// In pt_BR, this message translates to:
  /// **'Alta'**
  String get priorityHigh;

  /// Prioridade: crítica
  ///
  /// In pt_BR, this message translates to:
  /// **'Crítica'**
  String get priorityCritical;

  /// Prioridade: urgente
  ///
  /// In pt_BR, this message translates to:
  /// **'Urgente'**
  String get priorityUrgent;

  /// Tamanho: grande
  ///
  /// In pt_BR, this message translates to:
  /// **'Grande'**
  String get sizeBig;

  /// Tamanho: médio
  ///
  /// In pt_BR, this message translates to:
  /// **'Médio'**
  String get sizeMedium;

  /// Tamanho: pequeno
  ///
  /// In pt_BR, this message translates to:
  /// **'Pequeno'**
  String get sizeSmall;

  /// Tamanho: nenhum
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum'**
  String get sizeNone;

  /// Tipo de item: tarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Tarefa'**
  String get typeTask;

  /// Tipo de item: projeto
  ///
  /// In pt_BR, this message translates to:
  /// **'Projeto'**
  String get typeProject;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
