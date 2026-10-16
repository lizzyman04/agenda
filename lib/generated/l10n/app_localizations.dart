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

  /// Rótulo da aba de finanças na barra de navegação inferior
  ///
  /// In pt_BR, this message translates to:
  /// **'Finanças'**
  String get financeTabLabel;

  /// Rótulo da sub-aba Resumo na tela de finanças
  ///
  /// In pt_BR, this message translates to:
  /// **'Resumo'**
  String get dashboardTabLabel;

  /// Rótulo da sub-aba Transações na tela de finanças
  ///
  /// In pt_BR, this message translates to:
  /// **'Transações'**
  String get transactionsTabLabel;

  /// Rótulo da sub-aba Orçamentos na tela de finanças
  ///
  /// In pt_BR, this message translates to:
  /// **'Orçamentos'**
  String get budgetsTabLabel;

  /// Rótulo da sub-aba Objetivos na tela de finanças
  ///
  /// In pt_BR, this message translates to:
  /// **'Objetivos'**
  String get goalsTabLabel;

  /// Rótulo da sub-aba Dívidas na tela de finanças
  ///
  /// In pt_BR, this message translates to:
  /// **'Dívidas'**
  String get debtsTabLabel;

  /// Rótulo da sub-aba Recorrências na tela de finanças
  ///
  /// In pt_BR, this message translates to:
  /// **'Recorrências'**
  String get recurringTabLabel;

  /// Tooltip do FAB na tela de transações
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar transação'**
  String get addTransaction;

  /// Tooltip do FAB na tela de objetivos
  ///
  /// In pt_BR, this message translates to:
  /// **'Criar objetivo'**
  String get addGoal;

  /// Tooltip do FAB na tela de dívidas
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar dívida'**
  String get addDebt;

  /// Tooltip do FAB na tela de pagamentos recorrentes
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar pagamento'**
  String get addRecurring;

  /// Botão de adicionar contribuição na tela de detalhe do objetivo
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar contribuição'**
  String get addContribution;

  /// Rótulo do FilledButton na AppBar do formulário de transação
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar transação'**
  String get saveTransaction;

  /// Rótulo do FilledButton na AppBar do formulário de objetivo
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar objetivo'**
  String get saveGoal;

  /// Rótulo do FilledButton na AppBar do formulário de dívida
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar dívida'**
  String get saveDebt;

  /// Rótulo do FilledButton na AppBar do formulário de pagamento recorrente
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar pagamento'**
  String get saveRecurringPayment;

  /// Botão de salvar no BottomSheet de orçamento
  ///
  /// In pt_BR, this message translates to:
  /// **'Definir limite'**
  String get setBudgetLimit;

  /// Título do estado vazio na tela de transações
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma transação'**
  String get emptyTransactions;

  /// Corpo do estado vazio na tela de transações
  ///
  /// In pt_BR, this message translates to:
  /// **'Registre sua primeira receita ou despesa.'**
  String get emptyTransactionsBody;

  /// Título do estado vazio na tela de orçamentos
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem orçamentos'**
  String get emptyBudgets;

  /// Corpo do estado vazio na tela de orçamentos
  ///
  /// In pt_BR, this message translates to:
  /// **'Defina um limite mensal por categoria.'**
  String get emptyBudgetsBody;

  /// Título do estado vazio na tela de objetivos
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum objetivo'**
  String get emptyGoals;

  /// Corpo do estado vazio na tela de objetivos
  ///
  /// In pt_BR, this message translates to:
  /// **'Crie sua primeira meta de poupança.'**
  String get emptyGoalsBody;

  /// Título do estado vazio na tela de dívidas
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma dívida'**
  String get emptyDebts;

  /// Corpo do estado vazio na tela de dívidas
  ///
  /// In pt_BR, this message translates to:
  /// **'Registre valores a pagar ou a receber.'**
  String get emptyDebtsBody;

  /// Título do estado vazio na tela de pagamentos recorrentes
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem pagamentos recorrentes'**
  String get emptyRecurring;

  /// Corpo do estado vazio na tela de pagamentos recorrentes
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicione assinaturas e contas fixas.'**
  String get emptyRecurringBody;

  /// Título do estado vazio no painel de finanças
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem dados financeiros'**
  String get emptyDashboard;

  /// Corpo do estado vazio no painel de finanças
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicione transações para ver seu resumo.'**
  String get emptyDashboardBody;

  /// Rótulo do saldo no cartão de resumo do painel
  ///
  /// In pt_BR, this message translates to:
  /// **'Saldo atual'**
  String get currentBalance;

  /// Rótulo do patrimônio líquido no cartão de resumo do painel
  ///
  /// In pt_BR, this message translates to:
  /// **'Patrimônio líquido'**
  String get netWorth;

  /// Exibido na área do gráfico quando o mês selecionado não tem despesas
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem gastos em {month}'**
  String noExpensesInMonth(String month);

  /// Título da seção de gráficos do painel
  ///
  /// In pt_BR, this message translates to:
  /// **'Gastos por categoria'**
  String get spendingByCategory;

  /// Tooltip da seta de navegação para o mês anterior
  ///
  /// In pt_BR, this message translates to:
  /// **'Mês anterior'**
  String get previousMonth;

  /// Tooltip da seta de navegação para o próximo mês
  ///
  /// In pt_BR, this message translates to:
  /// **'Próximo mês'**
  String get nextMonth;

  /// Mensagem de erro ao falhar o carregamento
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível carregar os dados. Tente novamente.'**
  String get errorLoadFailed;

  /// Mensagem de erro ao falhar o salvamento
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível salvar. Verifique os campos e tente novamente.'**
  String get errorSaveFailed;

  /// Erro de validação quando o valor é zero ou vazio
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe um valor maior que zero.'**
  String get errorAmountRequired;

  /// Erro de validação quando o título está vazio (finanças)
  ///
  /// In pt_BR, this message translates to:
  /// **'O título é obrigatório.'**
  String get errorTitleRequired;

  /// Erro de validação quando nenhuma categoria está selecionada
  ///
  /// In pt_BR, this message translates to:
  /// **'Selecione uma categoria.'**
  String get errorCategoryRequired;

  /// Rótulo do campo de nota opcional no formulário de transação
  ///
  /// In pt_BR, this message translates to:
  /// **'Nota'**
  String get fieldNote;

  /// Rótulo do campo de categoria no formulário de transação
  ///
  /// In pt_BR, this message translates to:
  /// **'Categoria'**
  String get fieldCategory;

  /// Texto exibido quando nenhum limite de orçamento está definido para uma categoria
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem limite definido'**
  String get noLimitSet;

  /// Rótulo para o tipo de transação receita
  ///
  /// In pt_BR, this message translates to:
  /// **'Receita'**
  String get income;

  /// Rótulo para o tipo de transação despesa
  ///
  /// In pt_BR, this message translates to:
  /// **'Despesa'**
  String get expense;

  /// Conteúdo da SnackBar após exclusão suave de transação
  ///
  /// In pt_BR, this message translates to:
  /// **'Transação excluída'**
  String get transactionDeleted;

  /// Conteúdo da SnackBar após exclusão suave de dívida
  ///
  /// In pt_BR, this message translates to:
  /// **'Dívida excluída'**
  String get debtDeleted;

  /// Rótulo do interruptor num pagamento recorrente ativo
  ///
  /// In pt_BR, this message translates to:
  /// **'Ativo'**
  String get recurringActive;

  /// Rótulo do interruptor num pagamento recorrente pausado
  ///
  /// In pt_BR, this message translates to:
  /// **'Pausado'**
  String get recurringPaused;

  /// Título da AppBar ao editar uma transação
  ///
  /// In pt_BR, this message translates to:
  /// **'Editar transação'**
  String get editTransaction;

  /// Tooltip do botão de excluir objetivo
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir objetivo'**
  String get deleteGoal;

  /// Rótulo para dívidas a pagar
  ///
  /// In pt_BR, this message translates to:
  /// **'A pagar'**
  String get toPay;

  /// Rótulo para dívidas a receber
  ///
  /// In pt_BR, this message translates to:
  /// **'A receber'**
  String get toReceive;

  /// Rótulo da seção de vinculação financeira no formulário de tarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Vincular a...'**
  String get linkToFinance;

  /// Rótulo do chip de vinculação na tela de detalhe de tarefa
  ///
  /// In pt_BR, this message translates to:
  /// **'Ligado a'**
  String get linkedTo;

  /// Categoria de despesa: alimentação
  ///
  /// In pt_BR, this message translates to:
  /// **'Alimentação'**
  String get categoryAlimentacao;

  /// Categoria de despesa: transporte
  ///
  /// In pt_BR, this message translates to:
  /// **'Transporte'**
  String get categoryTransporte;

  /// Categoria de despesa: moradia
  ///
  /// In pt_BR, this message translates to:
  /// **'Moradia'**
  String get categoryMoradia;

  /// Categoria de despesa: saúde
  ///
  /// In pt_BR, this message translates to:
  /// **'Saúde'**
  String get categorySaude;

  /// Categoria de despesa: educação
  ///
  /// In pt_BR, this message translates to:
  /// **'Educação'**
  String get categoryEducacao;

  /// Categoria de despesa: lazer
  ///
  /// In pt_BR, this message translates to:
  /// **'Lazer'**
  String get categoryLazer;

  /// Categoria de despesa: roupas
  ///
  /// In pt_BR, this message translates to:
  /// **'Roupas'**
  String get categoryRoupas;

  /// Categoria de despesa: tecnologia
  ///
  /// In pt_BR, this message translates to:
  /// **'Tecnologia'**
  String get categoryTecnologia;

  /// Categoria de despesa/receita: outros
  ///
  /// In pt_BR, this message translates to:
  /// **'Outros'**
  String get categoryOutros;

  /// Categoria de receita: salário
  ///
  /// In pt_BR, this message translates to:
  /// **'Salário'**
  String get categorySalario;

  /// Categoria de receita: freelance
  ///
  /// In pt_BR, this message translates to:
  /// **'Freelance'**
  String get categoryFreelance;

  /// Categoria de receita: investimentos
  ///
  /// In pt_BR, this message translates to:
  /// **'Investimentos'**
  String get categoryInvestimentos;

  /// Nome do canal de notificação Android: lembretes de tarefas
  ///
  /// In pt_BR, this message translates to:
  /// **'Lembretes de tarefas'**
  String get notifChannelTasksName;

  /// Descrição do canal de notificação Android: lembretes de tarefas
  ///
  /// In pt_BR, this message translates to:
  /// **'Lembretes pouco antes de uma tarefa vencer'**
  String get notifChannelTasksDesc;

  /// Nome do canal de notificação Android: tarefas recorrentes
  ///
  /// In pt_BR, this message translates to:
  /// **'Lembretes de tarefas recorrentes'**
  String get notifChannelRecurringName;

  /// Descrição do canal de notificação Android: tarefas recorrentes
  ///
  /// In pt_BR, this message translates to:
  /// **'Lembretes de tarefas que se repetem'**
  String get notifChannelRecurringDesc;

  /// Nome do canal de notificação Android: resumo da manhã
  ///
  /// In pt_BR, this message translates to:
  /// **'Resumo da manhã'**
  String get notifChannelBriefingName;

  /// Descrição do canal de notificação Android: resumo da manhã
  ///
  /// In pt_BR, this message translates to:
  /// **'Um resumo das tarefas de hoje'**
  String get notifChannelBriefingDesc;

  /// Nome do canal de notificação Android: alertas de orçamento
  ///
  /// In pt_BR, this message translates to:
  /// **'Alertas de orçamento'**
  String get notifChannelBudgetName;

  /// Descrição do canal de notificação Android: alertas de orçamento
  ///
  /// In pt_BR, this message translates to:
  /// **'Alertas quando os gastos chegam a 80% e 100% de um orçamento'**
  String get notifChannelBudgetDesc;

  /// Nome do canal de notificação Android: lembretes de dívidas
  ///
  /// In pt_BR, this message translates to:
  /// **'Lembretes de dívidas'**
  String get notifChannelDebtsName;

  /// Descrição do canal de notificação Android: lembretes de dívidas
  ///
  /// In pt_BR, this message translates to:
  /// **'Um lembrete um dia antes do vencimento de uma dívida'**
  String get notifChannelDebtsDesc;

  /// Nome do canal de notificação Android: alertas de metas
  ///
  /// In pt_BR, this message translates to:
  /// **'Alertas de metas'**
  String get notifChannelGoalsName;

  /// Descrição do canal de notificação Android: alertas de metas
  ///
  /// In pt_BR, this message translates to:
  /// **'Alertas quando uma meta de economia fica atrasada'**
  String get notifChannelGoalsDesc;

  /// Nome do canal de notificação Android: contas e assinaturas
  ///
  /// In pt_BR, this message translates to:
  /// **'Contas e assinaturas'**
  String get notifChannelPaymentsName;

  /// Descrição do canal de notificação Android: contas e assinaturas
  ///
  /// In pt_BR, this message translates to:
  /// **'Um lembrete um dia antes de um pagamento recorrente'**
  String get notifChannelPaymentsDesc;

  /// Nome do canal de notificação Android: frases motivacionais
  ///
  /// In pt_BR, this message translates to:
  /// **'Frases motivacionais'**
  String get notifChannelQuotesName;

  /// Descrição do canal de notificação Android: frases motivacionais
  ///
  /// In pt_BR, this message translates to:
  /// **'Uma frase motivacional de vez em quando'**
  String get notifChannelQuotesDesc;

  /// Título da notificação: tarefa prestes a vencer
  ///
  /// In pt_BR, this message translates to:
  /// **'Tarefa prestes a vencer'**
  String get notifTaskReminderTitle;

  /// Corpo da notificação: título da tarefa e horário de vencimento
  ///
  /// In pt_BR, this message translates to:
  /// **'{title} vence às {time}'**
  String notifTaskReminderBody(String title, String time);

  /// Corpo da notificação: tarefa sem horário vence hoje
  ///
  /// In pt_BR, this message translates to:
  /// **'{title} vence hoje'**
  String notifTaskDueTodayBody(String title);

  /// Título da notificação: tarefa recorrente prestes a vencer
  ///
  /// In pt_BR, this message translates to:
  /// **'Tarefa recorrente prestes a vencer'**
  String get notifRecurringTaskTitle;

  /// Título do resumo da manhã com o número de tarefas de hoje
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, one{{count} tarefa para hoje} other{{count} tarefas para hoje}}'**
  String notifBriefingTitle(int count);

  /// Corpo do resumo da manhã: os primeiros títulos de tarefas, já unidos
  ///
  /// In pt_BR, this message translates to:
  /// **'{titles}'**
  String notifBriefingBody(String titles);

  /// Corpo do resumo da manhã quando há mais tarefas do que as listadas
  ///
  /// In pt_BR, this message translates to:
  /// **'{titles} e mais {remaining}'**
  String notifBriefingBodyMore(String titles, int remaining);

  /// Título do alerta de orçamento em 80% do limite (sem valores)
  ///
  /// In pt_BR, this message translates to:
  /// **'{category}: 80% do orçamento usado'**
  String notifBudget80Title(String category);

  /// Corpo do alerta de orçamento em 80% (sem valores)
  ///
  /// In pt_BR, this message translates to:
  /// **'Você usou 80% do limite deste mês.'**
  String get notifBudget80Body;

  /// Título do alerta de orçamento em 100% do limite (sem valores)
  ///
  /// In pt_BR, this message translates to:
  /// **'{category}: limite do orçamento atingido'**
  String notifBudget100Title(String category);

  /// Corpo do alerta de orçamento em 100% (sem valores)
  ///
  /// In pt_BR, this message translates to:
  /// **'Você atingiu o limite deste mês.'**
  String get notifBudget100Body;

  /// Título da notificação: dívida a pagar vence amanhã
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagamento vence amanhã'**
  String get notifDebtDueTitle;

  /// Título da notificação: dívida a receber vence amanhã
  ///
  /// In pt_BR, this message translates to:
  /// **'Valor a receber amanhã'**
  String get notifDebtReceiveTitle;

  /// Corpo da notificação de dívida: apenas o título
  ///
  /// In pt_BR, this message translates to:
  /// **'{title}'**
  String notifDebtBody(String title);

  /// Título da notificação: meta de economia atrasada
  ///
  /// In pt_BR, this message translates to:
  /// **'Meta ficando para trás'**
  String get notifGoalOffTrackTitle;

  /// Corpo da notificação: título da meta e um incentivo (sem valores)
  ///
  /// In pt_BR, this message translates to:
  /// **'{title} está atrasada. Uma pequena contribuição ajuda.'**
  String notifGoalOffTrackBody(String title);

  /// Título da notificação: pagamento recorrente vence amanhã
  ///
  /// In pt_BR, this message translates to:
  /// **'Conta vence amanhã'**
  String get notifPaymentDueTitle;

  /// Corpo da notificação de pagamento recorrente: apenas o título
  ///
  /// In pt_BR, this message translates to:
  /// **'{title}'**
  String notifPaymentBody(String title);

  /// Título da notificação de frase motivacional
  ///
  /// In pt_BR, this message translates to:
  /// **'Motivação do dia'**
  String get notifQuoteTitle;

  /// Título da página de configurações de notificações
  ///
  /// In pt_BR, this message translates to:
  /// **'Notificações'**
  String get notifSettingsTitle;

  /// Cabeçalho da seção dos interruptores por tipo
  ///
  /// In pt_BR, this message translates to:
  /// **'Tipos de notificação'**
  String get notifSettingsTypesHeader;

  /// Rótulo do seletor de horário do resumo da manhã
  ///
  /// In pt_BR, this message translates to:
  /// **'Horário do resumo'**
  String get notifSettingsBriefingTime;

  /// Cabeçalho da seção de frases motivacionais
  ///
  /// In pt_BR, this message translates to:
  /// **'Frases motivacionais'**
  String get notifSettingsQuotesHeader;

  /// Dica exibida enquanto as frases motivacionais estão desativadas
  ///
  /// In pt_BR, this message translates to:
  /// **'Ative as frases motivacionais para escolher a frequência.'**
  String get notifSettingsQuotesOffHint;

  /// Rótulo do controle de frequência das frases
  ///
  /// In pt_BR, this message translates to:
  /// **'Frequência'**
  String get notifSettingsQuoteFrequency;

  /// Opção de frequência das frases: todos os dias
  ///
  /// In pt_BR, this message translates to:
  /// **'Diária'**
  String get notifSettingsQuoteDaily;

  /// Opção de frequência das frases: uma vez por semana, às segundas
  ///
  /// In pt_BR, this message translates to:
  /// **'Semanal (segundas-feiras)'**
  String get notifSettingsQuoteWeekly;

  /// Rótulo do seletor de horário da frase
  ///
  /// In pt_BR, this message translates to:
  /// **'Horário da frase'**
  String get notifSettingsQuoteTime;

  /// Cabeçalho da seção de horário de silêncio
  ///
  /// In pt_BR, this message translates to:
  /// **'Horário de silêncio'**
  String get notifSettingsQuietHeader;

  /// Rótulo do interruptor: ativar horário de silêncio
  ///
  /// In pt_BR, this message translates to:
  /// **'Reter notificações no horário de silêncio'**
  String get notifSettingsQuietEnabled;

  /// Explica o que o horário de silêncio faz
  ///
  /// In pt_BR, this message translates to:
  /// **'Tudo que cair dentro deste período é entregue quando ele terminar.'**
  String get notifSettingsQuietDesc;

  /// Rótulo do início do horário de silêncio
  ///
  /// In pt_BR, this message translates to:
  /// **'Das'**
  String get notifSettingsQuietStart;

  /// Rótulo do fim do horário de silêncio
  ///
  /// In pt_BR, this message translates to:
  /// **'Até'**
  String get notifSettingsQuietEnd;

  /// Título do aviso quando a permissão de notificação é negada
  ///
  /// In pt_BR, this message translates to:
  /// **'As notificações estão desativadas'**
  String get notifSettingsPermissionDeniedTitle;

  /// Corpo do aviso quando a permissão de notificação é negada
  ///
  /// In pt_BR, this message translates to:
  /// **'Permita as notificações do AGENDA nas configurações do dispositivo para receber lembretes.'**
  String get notifSettingsPermissionDeniedBody;

  /// Botão que solicita a permissão de notificação
  ///
  /// In pt_BR, this message translates to:
  /// **'Permitir notificações'**
  String get notifSettingsAllowButton;

  /// Título do aviso sobre a permissão de alarmes exatos
  ///
  /// In pt_BR, this message translates to:
  /// **'Horários exatos dos lembretes'**
  String get notifSettingsExactTitle;

  /// Corpo do aviso sobre a permissão de alarmes exatos
  ///
  /// In pt_BR, this message translates to:
  /// **'O Android pode atrasar os lembretes se os alarmes exatos não forem permitidos.'**
  String get notifSettingsExactBody;

  /// Botão que abre a tela de permissão de alarmes exatos
  ///
  /// In pt_BR, this message translates to:
  /// **'Permitir alarmes exatos'**
  String get notifSettingsExactButton;

  /// Quantidade de lembretes adiados pelo limite de agendamento da plataforma
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, one{{count} lembrete aguarda um espaço livre} other{{count} lembretes aguardam um espaço livre}}'**
  String notifSettingsWaiting(int count);

  /// Nota de privacidade na página de configurações de notificações
  ///
  /// In pt_BR, this message translates to:
  /// **'Os lembretes são agendados somente neste dispositivo. Nada é enviado para lugar nenhum.'**
  String get notifSettingsPrivacyNote;

  /// Item do menu de configurações que abre a tela de backup
  ///
  /// In pt_BR, this message translates to:
  /// **'Backup e restauração'**
  String get backupMenuLabel;

  /// Título da tela de backup
  ///
  /// In pt_BR, this message translates to:
  /// **'Backup e restauração'**
  String get backupScreenTitle;

  /// Cabeçalho da seção de exportação
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportar'**
  String get backupExportHeader;

  /// Ação: exportar backup completo em JSON
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportar backup completo (JSON)'**
  String get backupExportJson;

  /// Descreve a exportação em JSON
  ///
  /// In pt_BR, this message translates to:
  /// **'Um arquivo com todas as tarefas, transações, orçamentos, metas, dívidas e pagamentos recorrentes.'**
  String get backupExportJsonDesc;

  /// Ação: exportar arquivos CSV
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportar planilhas (CSV)'**
  String get backupExportCsv;

  /// Descreve a exportação em CSV
  ///
  /// In pt_BR, this message translates to:
  /// **'Um arquivo CSV por tipo de dado, legível em qualquer aplicativo de planilhas.'**
  String get backupExportCsvDesc;

  /// Título do diálogo de salvar arquivo
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar backup'**
  String get backupExportSaveTitle;

  /// Mensagem após exportação JSON bem-sucedida
  ///
  /// In pt_BR, this message translates to:
  /// **'Backup salvo.'**
  String get backupExportDone;

  /// Mensagem após exportação CSV com o número de arquivos
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, one{{count} arquivo salvo.} other{{count} arquivos salvos.}}'**
  String backupExportCsvDone(int count);

  /// Mensagem quando o usuário cancela o diálogo de salvar
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportação cancelada.'**
  String get backupExportCancelled;

  /// Cabeçalho da seção de importação
  ///
  /// In pt_BR, this message translates to:
  /// **'Importar'**
  String get backupImportHeader;

  /// Ação: escolher um arquivo para importar
  ///
  /// In pt_BR, this message translates to:
  /// **'Importar arquivo de backup'**
  String get backupImportAction;

  /// Descreve o fluxo de importação
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolha um backup JSON ou um ou mais arquivos CSV. Um backup de segurança dos seus dados atuais é criado antes.'**
  String get backupImportDesc;

  /// Nota de privacidade: backups são arquivos simples
  ///
  /// In pt_BR, this message translates to:
  /// **'Os backups não são criptografados. Guarde-os em um local seguro. O AGENDA nunca envia seus dados.'**
  String get backupPrivacyNote;

  /// Nota sobre o backup automático do Android desativado
  ///
  /// In pt_BR, this message translates to:
  /// **'O backup em nuvem do Android está desativado para o AGENDA. Depois de reinstalar, restaure a partir de um arquivo JSON exportado.'**
  String get backupReinstallNote;

  /// Rótulo de progresso durante exportação ou importação
  ///
  /// In pt_BR, this message translates to:
  /// **'Processando…'**
  String get backupWorking;

  /// Título da tela de confirmação de importação
  ///
  /// In pt_BR, this message translates to:
  /// **'Confirmar importação'**
  String get backupConfirmTitle;

  /// Aviso de que a importação substitui dados
  ///
  /// In pt_BR, this message translates to:
  /// **'Isto substitui os dados listados abaixo. Um backup de segurança é criado antes.'**
  String get backupConfirmWarning;

  /// Explica a substituição parcial (por tipo)
  ///
  /// In pt_BR, this message translates to:
  /// **'Somente os tipos de dados presentes nos arquivos são substituídos. O restante é mantido.'**
  String get backupConfirmPartial;

  /// Intervalo de datas coberto pelo arquivo, já formatado
  ///
  /// In pt_BR, this message translates to:
  /// **'Registros de {from} a {to}'**
  String backupConfirmDateRange(String from, String to);

  /// Quando o backup foi exportado, já formatado
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportado em {date}'**
  String backupConfirmExportedAt(String date);

  /// Número de registros excluídos (lixeira) no arquivo
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, one{Inclui {count} registro excluído.} other{Inclui {count} registros excluídos.}}'**
  String backupConfirmDeletedIncluded(int count);

  /// Cabeçalho da lista de avisos na tela de confirmação
  ///
  /// In pt_BR, this message translates to:
  /// **'Avisos'**
  String get backupConfirmWarningsTitle;

  /// Aviso sobre referências a registros ausentes do arquivo
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, one{{count} registro aponta para dados que não estão no arquivo.} other{{count} registros apontam para dados que não estão no arquivo.}}'**
  String backupWarnDanglingLinks(int count);

  /// Botão destrutivo de confirmação
  ///
  /// In pt_BR, this message translates to:
  /// **'Substituir meus dados'**
  String get backupConfirmButton;

  /// Uma linha do resumo da importação: rótulo e quantidade
  ///
  /// In pt_BR, this message translates to:
  /// **'{label}: {count}'**
  String backupCountLine(String label, int count);

  /// Rótulo de entidade do backup: tarefas
  ///
  /// In pt_BR, this message translates to:
  /// **'Tarefas'**
  String get backupEntityTasks;

  /// Rótulo de entidade do backup: transações
  ///
  /// In pt_BR, this message translates to:
  /// **'Transações'**
  String get backupEntityTransactions;

  /// Rótulo de entidade do backup: categorias
  ///
  /// In pt_BR, this message translates to:
  /// **'Categorias'**
  String get backupEntityCategories;

  /// Rótulo de entidade do backup: orçamentos
  ///
  /// In pt_BR, this message translates to:
  /// **'Orçamentos'**
  String get backupEntityBudgets;

  /// Rótulo de entidade do backup: metas
  ///
  /// In pt_BR, this message translates to:
  /// **'Metas'**
  String get backupEntityGoals;

  /// Rótulo de entidade do backup: dívidas
  ///
  /// In pt_BR, this message translates to:
  /// **'Dívidas'**
  String get backupEntityDebts;

  /// Rótulo de entidade do backup: pagamentos recorrentes
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagamentos recorrentes'**
  String get backupEntityPayments;

  /// Mensagem após importação bem-sucedida
  ///
  /// In pt_BR, this message translates to:
  /// **'Importação concluída.'**
  String get backupImportDone;

  /// Resultado da importação com o número de registros
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, one{{count} registro importado.} other{{count} registros importados.}}'**
  String backupImportDoneCount(int count);

  /// Erro de importação: arquivo não reconhecido
  ///
  /// In pt_BR, this message translates to:
  /// **'Este arquivo não é um backup válido do AGENDA.'**
  String get backupErrorUnsupported;

  /// Erro de importação: arquivo acima do limite de tamanho
  ///
  /// In pt_BR, this message translates to:
  /// **'Este arquivo é grande demais para importar.'**
  String get backupErrorTooLarge;

  /// Erro de importação: backup de versão mais nova que o app
  ///
  /// In pt_BR, this message translates to:
  /// **'Este backup foi criado por uma versão mais nova do AGENDA.'**
  String get backupErrorNewerVersion;

  /// Erro de importação: JSON e CSV selecionados juntos
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolha um backup JSON ou arquivos CSV, não os dois.'**
  String get backupErrorMixed;

  /// Erro de importação: tipo de dado CSV duplicado
  ///
  /// In pt_BR, this message translates to:
  /// **'Dois dos arquivos selecionados contêm o mesmo tipo de dado.'**
  String get backupErrorDuplicate;

  /// Mensagem genérica de falha
  ///
  /// In pt_BR, this message translates to:
  /// **'Algo deu errado. Seus dados não foram alterados.'**
  String get backupErrorGeneric;

  /// Mensagem de falha na importação com o caminho do backup de segurança
  ///
  /// In pt_BR, this message translates to:
  /// **'A importação falhou. Seus dados não foram alterados. Backup de segurança: {path}'**
  String backupErrorImportFailed(String path);
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
