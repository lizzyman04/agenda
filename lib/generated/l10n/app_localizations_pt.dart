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

  @override
  String get searchTasks => 'Pesquisar tarefas';

  @override
  String get recurrence => 'Recorrência';

  @override
  String get noRecurrence => 'Não repete';

  @override
  String get daily => 'Diário';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensal';

  @override
  String get yearly => 'Anual';

  @override
  String get titleRequired => 'Título é obrigatório';

  @override
  String get gtdFilterTitle => 'Filtro GTD';

  @override
  String get noGtdContexts => 'Nenhum contexto GTD encontrado';

  @override
  String get applyFilter => 'Aplicar';

  @override
  String get clearFilter => 'Limpar';

  @override
  String get navTasks => 'Tarefas';

  @override
  String get navEisenhower => 'Matriz';

  @override
  String get navDayPlanner => 'Planner';

  @override
  String get navGtd => 'GTD';

  @override
  String get advancedOptions => 'Opções avançadas';

  @override
  String get gtdGuide => 'Guia GTD';

  @override
  String get gtdQ1 => 'O que precisa ser feito?';

  @override
  String get gtdQ2 => 'Essa tarefa precisa absolutamente ser feita?';

  @override
  String get gtdQ3 => 'Outra pessoa pode fazer isso por você?';

  @override
  String get gtdQ4 => 'Pode ser feito em menos de 10 minutos?';

  @override
  String get gtdQ5 => 'Isso é importante para seus objetivos de longo prazo?';

  @override
  String get gtdQ6 => 'Qual é o prazo?';

  @override
  String get gtdQ7 => 'Qual é o impacto se não for feito?';

  @override
  String get gtdAnswerYes => 'Sim';

  @override
  String get gtdAnswerNo => 'Não';

  @override
  String get gtdDiscardMessage => 'Ótimo. Se não é necessário, deixe para lá.';

  @override
  String get gtdDelegateMessage =>
      'Delegue. Adicione uma nota \'Aguardando\' se precisar.';

  @override
  String get gtdDoItNowMessage => 'Faça agora! Menos de 10 minutos — só faça.';

  @override
  String get gtdDeadlineToday => 'Hoje';

  @override
  String get gtdDeadlineThisWeek => 'Esta semana';

  @override
  String get gtdDeadlineThisMonth => 'Este mês';

  @override
  String get gtdDeadlineCustom => 'Data personalizada';

  @override
  String get gtdImpactCritical => 'Crítico — tudo depende disso';

  @override
  String get gtdImpactHigh => 'Alto — grandes consequências';

  @override
  String get gtdImpactMedium => 'Médio — consequências visíveis';

  @override
  String get gtdImpactLow => 'Baixo — consequências menores';

  @override
  String get gtdImpactNone => 'Nenhum — pode ser descartado';

  @override
  String get filterApplied => 'Filtro aplicado';

  @override
  String get taskDetailTitle => 'Tarefa';

  @override
  String get editButton => 'Editar';

  @override
  String get deleteButton => 'Excluir';

  @override
  String get deleteConfirmTitle => 'Excluir tarefa?';

  @override
  String get deleteConfirmBody =>
      'A tarefa será removida. Você terá alguns segundos para desfazer.';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get labelStatus => 'Status';

  @override
  String get statusCompleted => 'Concluída';

  @override
  String get statusPending => 'Pendente';
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

  @override
  String get searchTasks => 'Pesquisar tarefas';

  @override
  String get recurrence => 'Recorrência';

  @override
  String get noRecurrence => 'Não repete';

  @override
  String get daily => 'Diário';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensal';

  @override
  String get yearly => 'Anual';

  @override
  String get titleRequired => 'Título é obrigatório';

  @override
  String get gtdFilterTitle => 'Filtro GTD';

  @override
  String get noGtdContexts => 'Nenhum contexto GTD encontrado';

  @override
  String get applyFilter => 'Aplicar';

  @override
  String get clearFilter => 'Limpar';

  @override
  String get navTasks => 'Tarefas';

  @override
  String get navEisenhower => 'Matriz';

  @override
  String get navDayPlanner => 'Planner';

  @override
  String get navGtd => 'GTD';

  @override
  String get advancedOptions => 'Opções avançadas';

  @override
  String get gtdGuide => 'Guia GTD';

  @override
  String get gtdQ1 => 'O que precisa ser feito?';

  @override
  String get gtdQ2 => 'Essa tarefa precisa absolutamente ser feita?';

  @override
  String get gtdQ3 => 'Outra pessoa pode fazer isso por você?';

  @override
  String get gtdQ4 => 'Pode ser feito em menos de 10 minutos?';

  @override
  String get gtdQ5 => 'Isso é importante para seus objetivos de longo prazo?';

  @override
  String get gtdQ6 => 'Qual é o prazo?';

  @override
  String get gtdQ7 => 'Qual é o impacto se não for feito?';

  @override
  String get gtdAnswerYes => 'Sim';

  @override
  String get gtdAnswerNo => 'Não';

  @override
  String get gtdDiscardMessage => 'Ótimo. Se não é necessário, deixe para lá.';

  @override
  String get gtdDelegateMessage =>
      'Delegue. Adicione uma nota \'Aguardando\' se precisar.';

  @override
  String get gtdDoItNowMessage => 'Faça agora! Menos de 10 minutos — só faça.';

  @override
  String get gtdDeadlineToday => 'Hoje';

  @override
  String get gtdDeadlineThisWeek => 'Esta semana';

  @override
  String get gtdDeadlineThisMonth => 'Este mês';

  @override
  String get gtdDeadlineCustom => 'Data personalizada';

  @override
  String get gtdImpactCritical => 'Crítico — tudo depende disso';

  @override
  String get gtdImpactHigh => 'Alto — grandes consequências';

  @override
  String get gtdImpactMedium => 'Médio — consequências visíveis';

  @override
  String get gtdImpactLow => 'Baixo — consequências menores';

  @override
  String get gtdImpactNone => 'Nenhum — pode ser descartado';

  @override
  String get filterApplied => 'Filtro aplicado';

  @override
  String get taskDetailTitle => 'Tarefa';

  @override
  String get editButton => 'Editar';

  @override
  String get deleteButton => 'Excluir';

  @override
  String get deleteConfirmTitle => 'Excluir tarefa?';

  @override
  String get deleteConfirmBody =>
      'A tarefa será removida. Você terá alguns segundos para desfazer.';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get labelStatus => 'Status';

  @override
  String get statusCompleted => 'Concluída';

  @override
  String get statusPending => 'Pendente';
}
