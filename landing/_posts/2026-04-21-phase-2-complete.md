---
layout: post
title: "Fase 2 Completa: Gerenciamento de Tarefas está Aqui"
date: 2026-04-21 12:00:00 -0300
lang: pt
ref: phase-2-complete
permalink: /blog/2026/04/21/fase-2-completa/
tags: [desenvolvimento, flutter, tarefas, fase-2]
excerpt: "O núcleo de tarefas do AGENDA está pronto: Eisenhower, 1-3-5, GTD, projetos e subtarefas, tarefas recorrentes, busca e filtros."
---

A **Fase 2 do AGENDA** está completa. O núcleo de tarefas funciona de ponta a ponta, e tudo fica guardado localmente no seu dispositivo.

## O que foi construído

**Matriz de Eisenhower** — Um grid 2×2 que classifica tarefas por urgência e importância. Faça imediatamente o que é urgente e importante. Planeje o que é importante mas não urgente. Delegue o urgente não importante. Elimine o resto.

**Regra 1-3-5** — Cada dia começa com uma intenção clara: 1 tarefa grande, 3 médias, 5 pequenas. O AGENDA aplica essa restrição automaticamente, impedindo a lista infinita que nunca termina.

**GTD (Getting Things Done)** — Próximas ações, contextos e aguardando, mais um questionário guiado que ajuda a decidir o que fazer com cada item.

Em volta dos três frameworks:

- Projetos com subtarefas e progresso acumulado
- Tarefas recorrentes (diária, semanal, mensal, anual)
- Busca por palavra-chave
- Filtros por projeto, quadrante de Eisenhower, contexto GTD e intervalo de datas
- Desfazer por 5 segundos depois de excluir algo

## Por dentro

O estado vive em Cubits, então as telas só reagem ao estado e enviam intenções.

Tudo é guardado no dispositivo com o Isar Community, o fork mantido do Isar original (abandonado desde 2023). Sem SQLite e sem arquivos JSON — queries tipadas escritas direto em Dart.

## Próximos passos

A Fase 3 (finanças) começou em seguida.

*Atualização, outubro de 2026: a Fase 3 também está concluída. Veja o [roadmap]({{ '/dev/' | relative_url }}#roadmap).*
