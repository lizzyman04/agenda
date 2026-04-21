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

  /// Texto de dica na barra de pesquisa da lista de tarefas
  ///
  /// In pt_BR, this message translates to:
  /// **'Pesquisar tarefas'**
  String get searchTasks;

  /// Rótulo para a seção do seletor de regra de recorrência
  ///
  /// In pt_BR, this message translates to:
  /// **'Recorrência'**
  String get recurrence;

  /// Opção de rádio: sem recorrência
  ///
  /// In pt_BR, this message translates to:
  /// **'Não repete'**
  String get noRecurrence;

  /// Opção de rádio: recorrência diária
  ///
  /// In pt_BR, this message translates to:
  /// **'Diário'**
  String get daily;

  /// Opção de rádio: recorrência semanal
  ///
  /// In pt_BR, this message translates to:
  /// **'Semanal'**
  String get weekly;

  /// Opção de rádio: recorrência mensal
  ///
  /// In pt_BR, this message translates to:
  /// **'Mensal'**
  String get monthly;

  /// Opção de rádio: recorrência anual
  ///
  /// In pt_BR, this message translates to:
  /// **'Anual'**
  String get yearly;

  /// Erro de validação quando o título está vazio (chave alternativa)
  ///
  /// In pt_BR, this message translates to:
  /// **'Título é obrigatório'**
  String get titleRequired;

  /// Título da AppBar para a tela de filtro GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Filtro GTD'**
  String get gtdFilterTitle;

  /// Texto de estado vazio na tela de filtro GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum contexto GTD encontrado'**
  String get noGtdContexts;

  /// Rótulo do botão aplicar na tela de filtro GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Aplicar'**
  String get applyFilter;

  /// Rótulo do botão limpar filtro na tela de filtro GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Limpar'**
  String get clearFilter;

  /// Rótulo da nav inferior para lista de tarefas
  ///
  /// In pt_BR, this message translates to:
  /// **'Tarefas'**
  String get navTasks;

  /// Rótulo da nav inferior para matriz Eisenhower
  ///
  /// In pt_BR, this message translates to:
  /// **'Matriz'**
  String get navEisenhower;

  /// Rótulo da nav inferior para planner diário
  ///
  /// In pt_BR, this message translates to:
  /// **'Planner'**
  String get navDayPlanner;

  /// Rótulo da nav inferior para filtro GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'GTD'**
  String get navGtd;

  /// Rótulo da seção expansível no formulário de tarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Opções avançadas'**
  String get advancedOptions;

  /// Rótulo do botão para abrir o fluxo guiado GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Guia GTD'**
  String get gtdGuide;

  /// Pergunta 1 do guia GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'O que precisa ser feito?'**
  String get gtdQ1;

  /// Pergunta 2 do guia GTD — verificação de necessidade
  ///
  /// In pt_BR, this message translates to:
  /// **'Esta tarefa precisa realmente ser feita?'**
  String get gtdQ2;

  /// Sub-pergunta GTD quando usuário diz que tarefa não é necessária
  ///
  /// In pt_BR, this message translates to:
  /// **'Por que você quer adicioná-la mesmo assim?'**
  String get gtdQ2bQuestion;

  /// Opção GTD Q2b: lembrete futuro
  ///
  /// In pt_BR, this message translates to:
  /// **'É um lembrete para o futuro (Algum Dia/Talvez)'**
  String get gtdQ2bSomedayMaybe;

  /// Opção GTD Q2b: ideia
  ///
  /// In pt_BR, this message translates to:
  /// **'É uma ideia que não quero esquecer'**
  String get gtdQ2bIdea;

  /// Opção GTD Q2b: delegação de terceiro
  ///
  /// In pt_BR, this message translates to:
  /// **'Alguém me pediu, mas não é minha responsabilidade'**
  String get gtdQ2bDelegated;

  /// Opção GTD Q2b: manter mesmo sem necessidade
  ///
  /// In pt_BR, this message translates to:
  /// **'Quero adicionar mesmo assim'**
  String get gtdQ2bKeepAnyway;

  /// Pergunta 3 do guia GTD — verificação de delegação
  ///
  /// In pt_BR, this message translates to:
  /// **'Outra pessoa pode fazer essa tarefa por você?'**
  String get gtdQ3;

  /// Sub-pergunta GTD para nome do delegado
  ///
  /// In pt_BR, this message translates to:
  /// **'Para quem você vai delegar?'**
  String get gtdQ3DelegateTo;

  /// Dica no campo de texto de delegação
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome da pessoa'**
  String get gtdQ3DelegateHint;

  /// Sub-pergunta GTD sobre lembrete de cobrança
  ///
  /// In pt_BR, this message translates to:
  /// **'Quer um lembrete para cobrar essa pessoa?'**
  String get gtdQ3FollowUp;

  /// Pergunta 4 do guia GTD — regra dos 10 minutos
  ///
  /// In pt_BR, this message translates to:
  /// **'Esta tarefa pode ser feita em menos de 10 minutos?'**
  String get gtdQ4;

  /// Sub-pergunta GTD quando tarefa é rápida mas não será feita agora
  ///
  /// In pt_BR, this message translates to:
  /// **'Por que não fazer agora?'**
  String get gtdQ4bQuestion;

  /// Opção GTD Q4b: ocupado
  ///
  /// In pt_BR, this message translates to:
  /// **'Estou ocupado no momento'**
  String get gtdQ4bBusy;

  /// Opção GTD Q4b: precisa de contexto
  ///
  /// In pt_BR, this message translates to:
  /// **'Preciso de mais contexto ou informação'**
  String get gtdQ4bNeedContext;

  /// Opção GTD Q4b: momento inadequado
  ///
  /// In pt_BR, this message translates to:
  /// **'Não é o momento certo'**
  String get gtdQ4bNotRightTime;

  /// Opção GTD Q4b: decidiu fazer agora
  ///
  /// In pt_BR, this message translates to:
  /// **'Você tem razão, vou fazer agora'**
  String get gtdQ4bDoItNow;

  /// Opção GTD Q4b: outro motivo
  ///
  /// In pt_BR, this message translates to:
  /// **'Outro motivo'**
  String get gtdQ4bOther;

  /// Pergunta 5 do guia GTD — verificação de importância
  ///
  /// In pt_BR, this message translates to:
  /// **'Esta tarefa é importante para seus objetivos e projetos?'**
  String get gtdQ5;

  /// Sub-pergunta GTD quando tarefa não é importante
  ///
  /// In pt_BR, this message translates to:
  /// **'Por que você quer mantê-la?'**
  String get gtdQ5bQuestion;

  /// Opção GTD Q5b: obrigação
  ///
  /// In pt_BR, this message translates to:
  /// **'É uma obrigação ou tarefa chata'**
  String get gtdQ5bObligation;

  /// Opção GTD Q5b: cobrança externa
  ///
  /// In pt_BR, this message translates to:
  /// **'Alguém está me cobrando'**
  String get gtdQ5bSomeoneAsking;

  /// Opção GTD Q5b: lembrete
  ///
  /// In pt_BR, this message translates to:
  /// **'Não quero esquecer'**
  String get gtdQ5bReminder;

  /// Opção GTD Q5b: cancelar
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar tarefa'**
  String get gtdQ5bCancelTask;

  /// Opção GTD Q5b: outro motivo
  ///
  /// In pt_BR, this message translates to:
  /// **'Outro motivo'**
  String get gtdQ5bOther;

  /// Pergunta 6 do guia GTD — prazo
  ///
  /// In pt_BR, this message translates to:
  /// **'Qual a data limite para esta tarefa ser concluída?'**
  String get gtdQ6;

  /// Opção de prazo GTD: próximos 20 dias
  ///
  /// In pt_BR, this message translates to:
  /// **'Próximos 20 dias'**
  String get gtdDeadlineNext20Days;

  /// Sub-pergunta GTD quando não há prazo definido
  ///
  /// In pt_BR, this message translates to:
  /// **'Por que não tem prazo?'**
  String get gtdQ6bQuestion;

  /// Opção GTD Q6b: hábito ou tarefa contínua
  ///
  /// In pt_BR, this message translates to:
  /// **'É algo contínuo ou hábito'**
  String get gtdQ6bHabit;

  /// Opção GTD Q6b: não urgente, lembrete
  ///
  /// In pt_BR, this message translates to:
  /// **'Não é urgente, mas preciso lembrar'**
  String get gtdQ6bNotUrgent;

  /// Opção GTD Q6b: sem pressa
  ///
  /// In pt_BR, this message translates to:
  /// **'Pode ser quando der tempo'**
  String get gtdQ6bWhenever;

  /// Opção GTD Q6b: outro motivo
  ///
  /// In pt_BR, this message translates to:
  /// **'Outro motivo'**
  String get gtdQ6bOther;

  /// Pergunta 7 do guia GTD — impacto
  ///
  /// In pt_BR, this message translates to:
  /// **'Qual o impacto se esta tarefa não for concluída?'**
  String get gtdQ7;

  /// Nível de impacto GTD: muito negativo
  ///
  /// In pt_BR, this message translates to:
  /// **'Muito negativo — tudo depende disso'**
  String get gtdImpactVeryNegative;

  /// Nível de impacto GTD: negativo
  ///
  /// In pt_BR, this message translates to:
  /// **'Negativo — objetivos importantes afetados'**
  String get gtdImpactNegative;

  /// Nível de impacto GTD: moderado
  ///
  /// In pt_BR, this message translates to:
  /// **'Moderado — alguns objetivos afetados'**
  String get gtdImpactModerate;

  /// Nível de impacto GTD: leve
  ///
  /// In pt_BR, this message translates to:
  /// **'Leve — poucos objetivos afetados'**
  String get gtdImpactLight;

  /// Nível de impacto GTD: muito leve
  ///
  /// In pt_BR, this message translates to:
  /// **'Muito leve — atrasos mínimos'**
  String get gtdImpactVeryLight;

  /// Sub-pergunta GTD quando impacto é nenhum
  ///
  /// In pt_BR, this message translates to:
  /// **'Por que manter a tarefa?'**
  String get gtdQ7bQuestion;

  /// Opção GTD Q7b: desejo pessoal
  ///
  /// In pt_BR, this message translates to:
  /// **'É um desejo pessoal'**
  String get gtdQ7bPersonalWish;

  /// Opção GTD Q7b: expectativa de terceiro
  ///
  /// In pt_BR, this message translates to:
  /// **'Alguém espera que eu faça'**
  String get gtdQ7bSomeoneExpects;

  /// Opção GTD Q7b: cancelar
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar tarefa'**
  String get gtdQ7bCancelTask;

  /// Opção GTD Q7b: outro motivo
  ///
  /// In pt_BR, this message translates to:
  /// **'Outro motivo'**
  String get gtdQ7bOther;

  /// Título do card de revisão final do GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Resumo da tarefa'**
  String get gtdReviewTitle;

  /// Rótulo de prazo no card de revisão GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Prazo'**
  String get gtdReviewDeadlineLabel;

  /// Rótulo de prioridade no card de revisão GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Prioridade'**
  String get gtdReviewPriorityLabel;

  /// Rótulo de importância no card de revisão GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Importante'**
  String get gtdReviewImportantLabel;

  /// Rótulo de urgência no card de revisão GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Urgente'**
  String get gtdReviewUrgentLabel;

  /// Rótulo de delegado no card de revisão GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Delegado para'**
  String get gtdReviewDelegatedLabel;

  /// Botão de editar no card de revisão GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Voltar e editar'**
  String get gtdReviewEdit;

  /// Botão de salvar no card de revisão GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar tarefa'**
  String get gtdReviewSave;

  /// Título do diálogo de confirmação de cancelamento GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar o guia?'**
  String get gtdCancelTitle;

  /// Mensagem do diálogo de cancelamento GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'O progresso será perdido.'**
  String get gtdCancelMessage;

  /// Botão de continuar no diálogo de cancelamento GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Continuar'**
  String get gtdCancelContinue;

  /// Botão de descartar no diálogo de cancelamento GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Descartar'**
  String get gtdCancelDiscard;

  /// Mensagem GTD quando tarefa é salva como Someday/Maybe
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvo como Algum Dia/Talvez.'**
  String get gtdSomedayMessage;

  /// Mensagem GTD quando tarefa é salva como ideia
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvo como ideia.'**
  String get gtdIdeaSavedMessage;

  /// Mensagem GTD quando usuário decide fazer a tarefa agora
  ///
  /// In pt_BR, this message translates to:
  /// **'Faça agora! Menos de 10 minutos — só faça. ✅'**
  String get gtdDoItNowMessage;

  /// Resposta sim do guia GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Sim'**
  String get gtdAnswerYes;

  /// Resposta não do guia GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Não'**
  String get gtdAnswerNo;

  /// Rótulo do botão pular no guia GTD
  ///
  /// In pt_BR, this message translates to:
  /// **'Pular'**
  String get gtdSkip;

  /// Mensagem GTD quando a tarefa não é acionável
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionado à lista Algum Dia/Talvez. Volte quando estiver pronto.'**
  String get gtdDiscardMessage;

  /// Mensagem GTD quando a tarefa é delegada
  ///
  /// In pt_BR, this message translates to:
  /// **'Delegado. Uma nota \'Aguardando\' foi adicionada.'**
  String get gtdDelegateMessage;

  /// Opção de prazo GTD: hoje
  ///
  /// In pt_BR, this message translates to:
  /// **'Hoje'**
  String get gtdDeadlineToday;

  /// Opção de prazo GTD: amanhã
  ///
  /// In pt_BR, this message translates to:
  /// **'Amanhã'**
  String get gtdDeadlineTomorrow;

  /// Opção de prazo GTD: esta semana
  ///
  /// In pt_BR, this message translates to:
  /// **'Esta semana'**
  String get gtdDeadlineThisWeek;

  /// Opção de prazo GTD: este mês
  ///
  /// In pt_BR, this message translates to:
  /// **'Este mês'**
  String get gtdDeadlineThisMonth;

  /// Opção de prazo GTD: sem prazo
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem prazo'**
  String get gtdDeadlineNoDeadline;

  /// Opção de prazo GTD: personalizada
  ///
  /// In pt_BR, this message translates to:
  /// **'Data personalizada'**
  String get gtdDeadlineCustom;

  /// Nível de impacto GTD 1 (legado)
  ///
  /// In pt_BR, this message translates to:
  /// **'Crítico — tudo depende disso'**
  String get gtdImpactCritical;

  /// Nível de impacto GTD 2 (legado)
  ///
  /// In pt_BR, this message translates to:
  /// **'Alto — grandes consequências'**
  String get gtdImpactHigh;

  /// Nível de impacto GTD 3 (legado)
  ///
  /// In pt_BR, this message translates to:
  /// **'Médio — consequências visíveis'**
  String get gtdImpactMedium;

  /// Nível de impacto GTD 4 (legado)
  ///
  /// In pt_BR, this message translates to:
  /// **'Baixo — consequências menores'**
  String get gtdImpactLow;

  /// Nível de impacto GTD: nenhum
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum — pode ser descartado'**
  String get gtdImpactNone;

  /// Dica para o campo de texto Q3 (legado)
  ///
  /// In pt_BR, this message translates to:
  /// **'ex: Enviar e-mail, Ligar de volta, Redigir relatório'**
  String get gtdQ3Hint;

  /// Pergunta 8 do guia GTD — contexto (legado)
  ///
  /// In pt_BR, this message translates to:
  /// **'Qual é o contexto desta tarefa?'**
  String get gtdQ8;

  /// Dica para o campo de contexto Q8 (legado)
  ///
  /// In pt_BR, this message translates to:
  /// **'@casa, @computador, @escritório'**
  String get gtdQ8Hint;

  /// Confirmação após aplicar filtro GTD pela aba
  ///
  /// In pt_BR, this message translates to:
  /// **'Filtro aplicado'**
  String get filterApplied;

  /// Título da barra de apps na tela de detalhes da tarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Tarefa'**
  String get taskDetailTitle;

  /// Rótulo do botão de editar
  ///
  /// In pt_BR, this message translates to:
  /// **'Editar'**
  String get editButton;

  /// Rótulo do botão de excluir
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir'**
  String get deleteButton;

  /// Título do diálogo de confirmação de exclusão
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir tarefa?'**
  String get deleteConfirmTitle;

  /// Texto do diálogo de confirmação de exclusão
  ///
  /// In pt_BR, this message translates to:
  /// **'A tarefa será removida. Você terá alguns segundos para desfazer.'**
  String get deleteConfirmBody;

  /// Rótulo do botão cancelar
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar'**
  String get cancelButton;

  /// Rótulo de status na tela de detalhes da tarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Status'**
  String get labelStatus;

  /// Valor de status quando a tarefa está concluída
  ///
  /// In pt_BR, this message translates to:
  /// **'Concluída'**
  String get statusCompleted;

  /// Valor de status quando a tarefa está pendente
  ///
  /// In pt_BR, this message translates to:
  /// **'Pendente'**
  String get statusPending;
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
