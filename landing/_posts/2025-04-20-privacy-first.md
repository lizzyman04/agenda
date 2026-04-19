---
layout: post
title: "Por que Privacidade em Primeiro Lugar Importa para Apps de Produtividade"
date: 2025-04-20 10:00:00 -0300
tags: [privacidade, filosofia, arquitetura, offline]
excerpt: "Em um mundo onde apps de produtividade são vetores de coleta de dados, o AGENDA escolhe um caminho diferente: seus dados nunca saem do dispositivo."
---

Quando você anota uma tarefa em um app de produtividade, o que acontece com essa informação?

Na maioria dos casos: ela vai para um servidor. É analisada para personalização. Entra em modelos de comportamento. Pode ser vendida, hackeada, descontinuada. E quando o serviço fechar — porque serviços fecham — seus dados somem com ele.

O AGENDA parte de uma premissa diferente: **seus dados são seus, e nunca deveriam sair do seu dispositivo.**

## O Problema com Apps de Produtividade Modernos

Apps populares de produtividade têm um modelo de negócio que depende dos seus dados ou da sua assinatura mensal. Isso cria incentivos que não estão alinhados com o usuário:

- **Sync obrigatório**: seus dados ficam em servidores de terceiros porque é o que viabiliza o modelo
- **Analytics comportamentais**: como você usa o app vira produto
- **Lock-in**: sair é difícil porque seus dados estão presos no ecossistema deles
- **Risco de descontinuação**: se a empresa fechar ou mudar de direção, você perde tudo

Não estamos falando de conspirações. É simplesmente o modelo de negócio que dominou o mercado.

## O que "Privacidade em Primeiro Lugar" significa na prática

No AGENDA, privacidade não é uma feature. É uma restrição de arquitetura.

> Se uma decisão de design viola a privacidade, essa decisão está errada — independente de outros benefícios.

Isso tem consequências concretas:

### 1. Sem analytics

Nenhuma chamada para Amplitude, Mixpanel, Firebase Analytics ou qualquer serviço similar. Sabemos zero sobre como você usa o app. Isso é intencional.

### 2. Sem crash reporting externo

Sem Sentry, sem Crashlytics. Se o app crashar, o log fica no dispositivo. Você pode nos enviar se quiser, mas não mandamos automaticamente.

### 3. Banco de dados 100% local

Usamos [Isar Community](https://pub.dev/packages/isar_community) — um banco de dados nativo que armazena tudo no dispositivo, com queries em Dart e performance excelente. Nenhum dado sai do aparelho.

### 4. Funcionalidade 100% offline

O AGENDA não tem modo "offline" — ele é offline por padrão. Não existe código de sincronização. Não existe lógica condicional baseada em conectividade. O app funciona em um avião, em um bunker, em qualquer lugar.

### 5. Código aberto

O código está em [github.com/lizzyman04/agenda](https://github.com/lizzyman04/agenda). Qualquer pessoa pode auditar, verificar as afirmações acima e contribuir.

## O Tradeoff Honesto

Privacidade local tem um custo real: **sem backup automático na nuvem**.

Se você perder o dispositivo sem ter feito backup manual (via exportação CSV/JSON), seus dados não são recuperáveis. Não temos cópia.

Isso não é descuido — é uma consequência direta do modelo. Preferiríamos ter um backup automático seguro no futuro, mas não faremos isso de forma que comprometa a promessa de privacidade.

Por enquanto: **use a exportação regularmente**. Suas tarefas e finanças merecem um backup local.

## Por que isso importa além da conveniência

Produtividade pessoal envolve informações sensíveis. Suas tarefas revelam seus projetos, suas preocupações, seus planos. Suas finanças revelam seus hábitos, suas dívidas, suas metas.

Esse tipo de dado não deveria existir em servidores de terceiros — não porque os serviços sejam maliciosos, mas porque concentração de dados cria risco. Basta um vazamento, uma aquisição, uma mudança de política.

O AGENDA é uma aposta: que existe um segmento de usuários que prefere controle real sobre conveniência de sync. Que "seus dados, só seus" é uma proposta de valor suficientemente forte para construir algo em cima.

Acreditamos que sim.

---

*O AGENDA está em desenvolvimento ativo. Acompanhe o progresso no [GitHub](https://github.com/lizzyman04/agenda).*
