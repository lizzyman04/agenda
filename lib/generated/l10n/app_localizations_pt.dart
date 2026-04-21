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
  String get gtdQ2 => 'Esta tarefa precisa realmente ser feita?';

  @override
  String get gtdQ2bQuestion => 'Por que você quer adicioná-la mesmo assim?';

  @override
  String get gtdQ2bSomedayMaybe =>
      'É um lembrete para o futuro (Algum Dia/Talvez)';

  @override
  String get gtdQ2bIdea => 'É uma ideia que não quero esquecer';

  @override
  String get gtdQ2bDelegated =>
      'Alguém me pediu, mas não é minha responsabilidade';

  @override
  String get gtdQ2bKeepAnyway => 'Quero adicionar mesmo assim';

  @override
  String get gtdQ3 => 'Outra pessoa pode fazer essa tarefa por você?';

  @override
  String get gtdQ3DelegateTo => 'Para quem você vai delegar?';

  @override
  String get gtdQ3DelegateHint => 'Nome da pessoa';

  @override
  String get gtdQ3FollowUp => 'Quer um lembrete para cobrar essa pessoa?';

  @override
  String get gtdQ4 => 'Esta tarefa pode ser feita em menos de 10 minutos?';

  @override
  String get gtdQ4bQuestion => 'Por que não fazer agora?';

  @override
  String get gtdQ4bBusy => 'Estou ocupado no momento';

  @override
  String get gtdQ4bNeedContext => 'Preciso de mais contexto ou informação';

  @override
  String get gtdQ4bNotRightTime => 'Não é o momento certo';

  @override
  String get gtdQ4bDoItNow => 'Você tem razão, vou fazer agora';

  @override
  String get gtdQ4bOther => 'Outro motivo';

  @override
  String get gtdQ5 =>
      'Esta tarefa é importante para seus objetivos e projetos?';

  @override
  String get gtdQ5bQuestion => 'Por que você quer mantê-la?';

  @override
  String get gtdQ5bObligation => 'É uma obrigação ou tarefa chata';

  @override
  String get gtdQ5bSomeoneAsking => 'Alguém está me cobrando';

  @override
  String get gtdQ5bReminder => 'Não quero esquecer';

  @override
  String get gtdQ5bCancelTask => 'Cancelar tarefa';

  @override
  String get gtdQ5bOther => 'Outro motivo';

  @override
  String get gtdQ6 => 'Qual a data limite para esta tarefa ser concluída?';

  @override
  String get gtdDeadlineNext20Days => 'Próximos 20 dias';

  @override
  String get gtdQ6bQuestion => 'Por que não tem prazo?';

  @override
  String get gtdQ6bHabit => 'É algo contínuo ou hábito';

  @override
  String get gtdQ6bNotUrgent => 'Não é urgente, mas preciso lembrar';

  @override
  String get gtdQ6bWhenever => 'Pode ser quando der tempo';

  @override
  String get gtdQ6bOther => 'Outro motivo';

  @override
  String get gtdQ7 => 'Qual o impacto se esta tarefa não for concluída?';

  @override
  String get gtdImpactVeryNegative => 'Muito negativo — tudo depende disso';

  @override
  String get gtdImpactNegative => 'Negativo — objetivos importantes afetados';

  @override
  String get gtdImpactModerate => 'Moderado — alguns objetivos afetados';

  @override
  String get gtdImpactLight => 'Leve — poucos objetivos afetados';

  @override
  String get gtdImpactVeryLight => 'Muito leve — atrasos mínimos';

  @override
  String get gtdQ7bQuestion => 'Por que manter a tarefa?';

  @override
  String get gtdQ7bPersonalWish => 'É um desejo pessoal';

  @override
  String get gtdQ7bSomeoneExpects => 'Alguém espera que eu faça';

  @override
  String get gtdQ7bCancelTask => 'Cancelar tarefa';

  @override
  String get gtdQ7bOther => 'Outro motivo';

  @override
  String get gtdReviewTitle => 'Resumo da tarefa';

  @override
  String get gtdReviewDeadlineLabel => 'Prazo';

  @override
  String get gtdReviewPriorityLabel => 'Prioridade';

  @override
  String get gtdReviewImportantLabel => 'Importante';

  @override
  String get gtdReviewUrgentLabel => 'Urgente';

  @override
  String get gtdReviewDelegatedLabel => 'Delegado para';

  @override
  String get gtdReviewEdit => 'Voltar e editar';

  @override
  String get gtdReviewSave => 'Salvar tarefa';

  @override
  String get gtdCancelTitle => 'Cancelar o guia?';

  @override
  String get gtdCancelMessage => 'O progresso será perdido.';

  @override
  String get gtdCancelContinue => 'Continuar';

  @override
  String get gtdCancelDiscard => 'Descartar';

  @override
  String get gtdSomedayMessage => 'Salvo como Algum Dia/Talvez.';

  @override
  String get gtdIdeaSavedMessage => 'Salvo como ideia.';

  @override
  String get gtdDoItNowMessage =>
      'Faça agora! Menos de 10 minutos — só faça. ✅';

  @override
  String get gtdAnswerYes => 'Sim';

  @override
  String get gtdAnswerNo => 'Não';

  @override
  String get gtdSkip => 'Pular';

  @override
  String get gtdDiscardMessage =>
      'Adicionado à lista Algum Dia/Talvez. Volte quando estiver pronto.';

  @override
  String get gtdDelegateMessage =>
      'Delegado. Uma nota \'Aguardando\' foi adicionada.';

  @override
  String get gtdDeadlineToday => 'Hoje';

  @override
  String get gtdDeadlineTomorrow => 'Amanhã';

  @override
  String get gtdDeadlineThisWeek => 'Esta semana';

  @override
  String get gtdDeadlineThisMonth => 'Este mês';

  @override
  String get gtdDeadlineNoDeadline => 'Sem prazo';

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
  String get gtdQ3Hint =>
      'ex: Enviar e-mail, Ligar de volta, Redigir relatório';

  @override
  String get gtdQ8 => 'Qual é o contexto desta tarefa?';

  @override
  String get gtdQ8Hint => '@casa, @computador, @escritório';

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
  String get gtdQ2 => 'Esta tarefa precisa realmente ser feita?';

  @override
  String get gtdQ2bQuestion => 'Por que você quer adicioná-la mesmo assim?';

  @override
  String get gtdQ2bSomedayMaybe =>
      'É um lembrete para o futuro (Algum Dia/Talvez)';

  @override
  String get gtdQ2bIdea => 'É uma ideia que não quero esquecer';

  @override
  String get gtdQ2bDelegated =>
      'Alguém me pediu, mas não é minha responsabilidade';

  @override
  String get gtdQ2bKeepAnyway => 'Quero adicionar mesmo assim';

  @override
  String get gtdQ3 => 'Outra pessoa pode fazer essa tarefa por você?';

  @override
  String get gtdQ3DelegateTo => 'Para quem você vai delegar?';

  @override
  String get gtdQ3DelegateHint => 'Nome da pessoa';

  @override
  String get gtdQ3FollowUp => 'Quer um lembrete para cobrar essa pessoa?';

  @override
  String get gtdQ4 => 'Esta tarefa pode ser feita em menos de 10 minutos?';

  @override
  String get gtdQ4bQuestion => 'Por que não fazer agora?';

  @override
  String get gtdQ4bBusy => 'Estou ocupado no momento';

  @override
  String get gtdQ4bNeedContext => 'Preciso de mais contexto ou informação';

  @override
  String get gtdQ4bNotRightTime => 'Não é o momento certo';

  @override
  String get gtdQ4bDoItNow => 'Você tem razão, vou fazer agora';

  @override
  String get gtdQ4bOther => 'Outro motivo';

  @override
  String get gtdQ5 =>
      'Esta tarefa é importante para seus objetivos e projetos?';

  @override
  String get gtdQ5bQuestion => 'Por que você quer mantê-la?';

  @override
  String get gtdQ5bObligation => 'É uma obrigação ou tarefa chata';

  @override
  String get gtdQ5bSomeoneAsking => 'Alguém está me cobrando';

  @override
  String get gtdQ5bReminder => 'Não quero esquecer';

  @override
  String get gtdQ5bCancelTask => 'Cancelar tarefa';

  @override
  String get gtdQ5bOther => 'Outro motivo';

  @override
  String get gtdQ6 => 'Qual a data limite para esta tarefa ser concluída?';

  @override
  String get gtdDeadlineNext20Days => 'Próximos 20 dias';

  @override
  String get gtdQ6bQuestion => 'Por que não tem prazo?';

  @override
  String get gtdQ6bHabit => 'É algo contínuo ou hábito';

  @override
  String get gtdQ6bNotUrgent => 'Não é urgente, mas preciso lembrar';

  @override
  String get gtdQ6bWhenever => 'Pode ser quando der tempo';

  @override
  String get gtdQ6bOther => 'Outro motivo';

  @override
  String get gtdQ7 => 'Qual o impacto se esta tarefa não for concluída?';

  @override
  String get gtdImpactVeryNegative => 'Muito negativo — tudo depende disso';

  @override
  String get gtdImpactNegative => 'Negativo — objetivos importantes afetados';

  @override
  String get gtdImpactModerate => 'Moderado — alguns objetivos afetados';

  @override
  String get gtdImpactLight => 'Leve — poucos objetivos afetados';

  @override
  String get gtdImpactVeryLight => 'Muito leve — atrasos mínimos';

  @override
  String get gtdQ7bQuestion => 'Por que manter a tarefa?';

  @override
  String get gtdQ7bPersonalWish => 'É um desejo pessoal';

  @override
  String get gtdQ7bSomeoneExpects => 'Alguém espera que eu faça';

  @override
  String get gtdQ7bCancelTask => 'Cancelar tarefa';

  @override
  String get gtdQ7bOther => 'Outro motivo';

  @override
  String get gtdReviewTitle => 'Resumo da tarefa';

  @override
  String get gtdReviewDeadlineLabel => 'Prazo';

  @override
  String get gtdReviewPriorityLabel => 'Prioridade';

  @override
  String get gtdReviewImportantLabel => 'Importante';

  @override
  String get gtdReviewUrgentLabel => 'Urgente';

  @override
  String get gtdReviewDelegatedLabel => 'Delegado para';

  @override
  String get gtdReviewEdit => 'Voltar e editar';

  @override
  String get gtdReviewSave => 'Salvar tarefa';

  @override
  String get gtdCancelTitle => 'Cancelar o guia?';

  @override
  String get gtdCancelMessage => 'O progresso será perdido.';

  @override
  String get gtdCancelContinue => 'Continuar';

  @override
  String get gtdCancelDiscard => 'Descartar';

  @override
  String get gtdSomedayMessage => 'Salvo como Algum Dia/Talvez.';

  @override
  String get gtdIdeaSavedMessage => 'Salvo como ideia.';

  @override
  String get gtdDoItNowMessage =>
      'Faça agora! Menos de 10 minutos — só faça. ✅';

  @override
  String get gtdAnswerYes => 'Sim';

  @override
  String get gtdAnswerNo => 'Não';

  @override
  String get gtdSkip => 'Pular';

  @override
  String get gtdDiscardMessage =>
      'Adicionado à lista Algum Dia/Talvez. Volte quando estiver pronto.';

  @override
  String get gtdDelegateMessage =>
      'Delegado. Uma nota \'Aguardando\' foi adicionada.';

  @override
  String get gtdDeadlineToday => 'Hoje';

  @override
  String get gtdDeadlineTomorrow => 'Amanhã';

  @override
  String get gtdDeadlineThisWeek => 'Esta semana';

  @override
  String get gtdDeadlineThisMonth => 'Este mês';

  @override
  String get gtdDeadlineNoDeadline => 'Sem prazo';

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
  String get gtdQ3Hint =>
      'ex: Enviar e-mail, Ligar de volta, Redigir relatório';

  @override
  String get gtdQ8 => 'Qual é o contexto desta tarefa?';

  @override
  String get gtdQ8Hint => '@casa, @computador, @escritório';

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
