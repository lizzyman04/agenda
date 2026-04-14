// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'AGENDA';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get privacyStatement => 'Os seus dados nunca saem deste dispositivo.';

  @override
  String get emptyStateTitle => 'Nenhum item ainda';

  @override
  String get emptyStateAction => 'Toque para adicionar';

  @override
  String get tasksScreenTitle => 'Tarefas';

  @override
  String get noTasks => 'Nenhuma tarefa';

  @override
  String get taskDeleted => 'Tarefa excluída';

  @override
  String get undo => 'Desfazer';

  @override
  String get quadrantEmpty => 'Vazia';

  @override
  String get slotLimitExceeded => 'Limite excedido';

  @override
  String get slotLimitWarning => 'Limite de slot excedido';

  @override
  String get addTask => 'Adicionar';

  @override
  String get bigTask => '1 Grande Tarefa';

  @override
  String get mediumTasks => '3 Tarefas Médias';

  @override
  String get smallTasks => '5 Tarefas Pequenas';

  @override
  String get dayPlannerTitle => 'Planejamento 1-3-5';

  @override
  String get eisenhowerTitle => 'Matriz Eisenhower';

  @override
  String get eisenhowerDoNow => 'Fazer Agora';

  @override
  String get eisenhowerSchedule => 'Agendar';

  @override
  String get eisenhowerDelegate => 'Delegar';

  @override
  String get eisenhowerEliminate => 'Eliminar';

  @override
  String get taskFormTitleCreate => 'Nova Tarefa';

  @override
  String get taskFormTitleEdit => 'Editar Tarefa';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldTitleRequired => 'Título é obrigatório';

  @override
  String get fieldDescription => 'Descrição';

  @override
  String get fieldPriority => 'Prioridade';

  @override
  String get fieldDueDate => 'Prazo';

  @override
  String get fieldDueTime => 'Horário';

  @override
  String get noDueDate => 'Sem prazo';

  @override
  String get noDueTime => 'Sem hora';

  @override
  String get fieldUrgent => 'Urgente';

  @override
  String get fieldImportant => 'Importante';

  @override
  String get fieldSize => 'Tamanho';

  @override
  String get fieldNextAction => 'Próxima ação';

  @override
  String get fieldGtdContext => 'Contexto GTD';

  @override
  String get fieldWaitingFor => 'Aguardando';

  @override
  String get fieldAmount => 'Valor';

  @override
  String get fieldCurrency => 'Moeda';

  @override
  String get saveButton => 'Salvar';

  @override
  String get projectScreenTitle => 'Projeto';

  @override
  String subtasksProgress(int completed, int total) {
    return '$completed/$total subtarefas';
  }

  @override
  String get addSubtask => 'Adicionar subtarefa';

  @override
  String get subtaskTitleHint => 'Título da subtarefa';

  @override
  String get priorityLow => 'Baixa';

  @override
  String get priorityMedium => 'Média';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityCritical => 'Crítica';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get sizeBig => 'Grande';

  @override
  String get sizeMedium => 'Médio';

  @override
  String get sizeSmall => 'Pequeno';

  @override
  String get sizeNone => 'Nenhum';

  @override
  String get typeTask => 'Tarefa';

  @override
  String get typeProject => 'Projeto';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appName => 'AGENDA';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get privacyStatement => 'Os seus dados nunca saem deste dispositivo.';

  @override
  String get emptyStateTitle => 'Nenhum item ainda';

  @override
  String get emptyStateAction => 'Toque para adicionar';

  @override
  String get tasksScreenTitle => 'Tarefas';

  @override
  String get noTasks => 'Nenhuma tarefa';

  @override
  String get taskDeleted => 'Tarefa excluída';

  @override
  String get undo => 'Desfazer';

  @override
  String get quadrantEmpty => 'Vazia';

  @override
  String get slotLimitExceeded => 'Limite excedido';

  @override
  String get slotLimitWarning => 'Limite de slot excedido';

  @override
  String get addTask => 'Adicionar';

  @override
  String get bigTask => '1 Grande Tarefa';

  @override
  String get mediumTasks => '3 Tarefas Médias';

  @override
  String get smallTasks => '5 Tarefas Pequenas';

  @override
  String get dayPlannerTitle => 'Planejamento 1-3-5';

  @override
  String get eisenhowerTitle => 'Matriz Eisenhower';

  @override
  String get eisenhowerDoNow => 'Fazer Agora';

  @override
  String get eisenhowerSchedule => 'Agendar';

  @override
  String get eisenhowerDelegate => 'Delegar';

  @override
  String get eisenhowerEliminate => 'Eliminar';

  @override
  String get taskFormTitleCreate => 'Nova Tarefa';

  @override
  String get taskFormTitleEdit => 'Editar Tarefa';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldTitleRequired => 'Título é obrigatório';

  @override
  String get fieldDescription => 'Descrição';

  @override
  String get fieldPriority => 'Prioridade';

  @override
  String get fieldDueDate => 'Prazo';

  @override
  String get fieldDueTime => 'Horário';

  @override
  String get noDueDate => 'Sem prazo';

  @override
  String get noDueTime => 'Sem hora';

  @override
  String get fieldUrgent => 'Urgente';

  @override
  String get fieldImportant => 'Importante';

  @override
  String get fieldSize => 'Tamanho';

  @override
  String get fieldNextAction => 'Próxima ação';

  @override
  String get fieldGtdContext => 'Contexto GTD';

  @override
  String get fieldWaitingFor => 'Aguardando';

  @override
  String get fieldAmount => 'Valor';

  @override
  String get fieldCurrency => 'Moeda';

  @override
  String get saveButton => 'Salvar';

  @override
  String get projectScreenTitle => 'Projeto';

  @override
  String subtasksProgress(int completed, int total) {
    return '$completed/$total subtarefas';
  }

  @override
  String get addSubtask => 'Adicionar subtarefa';

  @override
  String get subtaskTitleHint => 'Título da subtarefa';

  @override
  String get priorityLow => 'Baixa';

  @override
  String get priorityMedium => 'Média';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityCritical => 'Crítica';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get sizeBig => 'Grande';

  @override
  String get sizeMedium => 'Médio';

  @override
  String get sizeSmall => 'Pequeno';

  @override
  String get sizeNone => 'Nenhum';

  @override
  String get typeTask => 'Tarefa';

  @override
  String get typeProject => 'Projeto';
}
