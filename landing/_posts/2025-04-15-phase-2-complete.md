---
layout: post
title: "Fase 2 Completa: Gerenciamento de Tarefas está Aqui"
date: 2025-04-15 12:00:00 -0300
tags: [desenvolvimento, flutter, tarefas, fase-2]
excerpt: "A Fase 2 do AGENDA está completa com 138 testes passando. O módulo de tarefas inclui Eisenhower, 1-3-5, GTD, subtarefas, projetos, recorrência e muito mais."
---

Depois de semanas de desenvolvimento intenso, a **Fase 2 do AGENDA** está oficialmente completa.

138 testes passando. Zero regressões. O módulo de tarefas está funcional de ponta a ponta.

## O que foi construído

A Fase 2 cobre todo o núcleo de gerenciamento de tarefas — desde a camada de domínio até a interface de usuário, passando pelo BLoC, repositórios Isar e os três frameworks de produtividade integrados.

### Frameworks de Produtividade

**Matriz de Eisenhower** — Um grid 2×2 que classifica tarefas por urgência e importância. Faça imediatamente o que é urgente e importante. Planeje o que é importante mas não urgente. Delegue o urgente não importante. Elimine o resto.

**Regra 1-3-5** — Cada dia começa com uma intenção clara: 1 tarefa grande, 3 médias, 5 pequenas. O AGENDA aplica essa restrição automaticamente, impedindo a lista infinita que nunca termina.

**GTD (Getting Things Done)** — Captura, processamento, organização por contexto e revisão semanal. Nada cai nas brechas.

### Gerenciamento de Projetos

- Projetos com subtarefas e progresso acumulado
- Tarefas recorrentes com reinicialização automática (diária, semanal, mensal)
- Busca por palavra-chave em tempo real
- Filtros avançados: status, prioridade, framework, data

### Interface

- `TaskListScreen` com tabs por framework
- `TaskFormScreen` com 14 campos, validação em tempo real
- `EisenhowerScreen` — grid 2×2 com drag-and-drop de quadrante
- `DayPlannerScreen` — visão da Regra 1-3-5 com slots visuais
- `GtdFilterScreen` — filtro por contexto GTD

## Decisões Técnicas

### BLoC como única fonte de verdade

Cada operação de tarefa — criar, atualizar, concluir, deletar, filtrar — passa pelo `TaskListCubit`. A UI nunca acessa o repositório diretamente. Isso torna o estado previsível e testável.

```dart
// Todas as operações passam pelo cubit
await cubit.createTask(params);
await cubit.toggleComplete(id);
await cubit.applyFilter(filter);
```

### Isar Community como banco de dados

Escolhemos `isar_community` (fork ativo do Isar original, abandonado desde 2023) pela performance de leitura nativa no dispositivo e pela API reativa via `watchQuery`. Sem SQLite, sem JSON em arquivo — queries tipadas diretamente em Dart.

### Testes sem mocks de banco

138 testes, todos contra repositórios reais com Isar em memória. Mocks só para dependências externas (notificações, auth). Isso nos ensinou uma lição importante em projetos anteriores: mocks de banco escondem problemas de schema e query que só aparecem em produção.

## Cobertura de Testes

| Camada       | Testes | Status |
|--------------|--------|--------|
| Domain       | 18     | Passando |
| Data (Isar)  | 34     | Passando |
| Application  | 52     | Passando |
| Presentation | 34     | Passando |
| **Total**    | **138**| **100%** |

## Próximos Passos

A **Fase 3 — Finance Core** começa agora. O objetivo: trazer o mesmo nível de completude para o módulo financeiro — transações, orçamentos, metas de economia, dívidas e um dashboard com gráficos.

O AGENDA está ganhando forma. Se você quiser acompanhar ou contribuir, o repositório é aberto: [github.com/lizzyman04/agenda](https://github.com/lizzyman04/agenda).
