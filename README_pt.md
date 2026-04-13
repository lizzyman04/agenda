<div align="center">

# AGENDA

### *Uma tarefa espera por você!*

**Sua central pessoal de tarefas e finanças — privada, offline, sempre pronta.**

<br>

[![Flutter](https://img.shields.io/badge/Flutter-3.41.4-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.1-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![CI](https://github.com/lizzyman04/agenda/actions/workflows/ci.yml/badge.svg)](https://github.com/lizzyman04/agenda/actions/workflows/ci.yml)
[![Licença](https://img.shields.io/badge/licença-MIT-green)](LICENSE)
[![Plataforma](https://img.shields.io/badge/plataforma-Android%20%7C%20iOS-lightgrey?logo=android&logoColor=white)](https://flutter.dev/multi-platform/mobile)
[![Privacidade](https://img.shields.io/badge/privacidade-100%25%20offline-blueviolet)](#privacidade-em-primeiro-lugar)

<br>

> Abra o AGENDA a qualquer momento — de manhã, ao meio-dia ou à noite —  
> e veja imediatamente **o que precisa ser feito** e **como estão suas finanças**,  
> sem precisar de internet.

</div>

---

## Capturas de Tela

<div align="center">

| Tarefas | Finanças | Painel |
|:-------:|:--------:|:------:|
| *(em breve)* | *(em breve)* | *(em breve)* |

</div>

---

## Funcionalidades

### Gerenciamento de Tarefas

| Framework | Descrição |
|-----------|-----------|
| **Matriz de Eisenhower** | Priorize por urgência × importância — foco no que realmente importa |
| **Regra 1-3-5** | Planeje cada dia com 1 tarefa grande, 3 médias e 5 pequenas — sem sobrecarga |
| **GTD** | Capture tudo, clarifique as ações, revise semanalmente e execute com confiança |

- Tarefas recorrentes com agendamentos flexíveis
- Lembretes e notificações locais
- 100% offline — sem sincronização, sem conta, sem dados saindo do dispositivo

### Controle Financeiro

| Funcionalidade | Descrição |
|----------------|-----------|
| **Receitas & Despesas** | Registre cada transação com categorias e anotações |
| **Orçamentos** | Defina limites mensais por categoria e acompanhe os gastos em tempo real |
| **Dívidas** | Controle o que você deve e o que lhe devem |
| **Metas de Economia** | Defina objetivos e acompanhe seu progresso |
| **Relatórios** | Gráficos e resumos visuais da sua saúde financeira |

- Exportação para CSV para análise externa
- Importação de CSV para migração de dados

---

## Privacidade em Primeiro Lugar

O AGENDA é construído em torno de um princípio inegociável: **seus dados nunca saem do dispositivo**.

- Sem analytics — nem mesmo relatórios anônimos de erros
- Sem sincronização na nuvem — nenhuma conta necessária, jamais
- Sem permissão de internet — o app não pode fazer requisições de rede
- Dados armazenados exclusivamente no banco de dados Isar local
- 100% funcional com o modo avião ativado

---

## Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| **Interface** | Flutter 3.41.4 (Android + iOS) |
| **Estado** | BLoC / Cubit (`flutter_bloc` 9.1.1) |
| **Banco de Dados** | Isar Community 3.3.2 (embarcado, no dispositivo) |
| **Injeção de Dependências** | GetIt 9.2.1 + Injectable 2.7.1 |
| **Navegação** | go_router 17.2.0 |
| **Localização** | flutter_localizations + intl (PT-BR padrão, alternância para EN) |
| **Notificações** | flutter_local_notifications 21.0.0 |
| **Bloqueio do App** | flutter_screen_lock + local_auth + flutter_secure_storage |
| **Gráficos** | fl_chart 1.2.0 |
| **Testes** | bloc_test + mocktail |
| **Lint** | very_good_analysis (rigoroso) |

---

## Primeiros Passos

### Pré-requisitos

- Flutter SDK `>=3.38.1` (testado com `3.41.4`)
- Dart SDK `>=3.11.0`
- Android SDK com dispositivo ou emulador conectado
- Xcode (para builds iOS)

### Configuração

```bash
# Clone o repositório
git clone https://github.com/lizzyman04/agenda.git
cd agenda

# Instale as dependências
flutter pub get

# Execute a geração de código (schemas Isar + grafo de DI)
dart run build_runner build --delete-conflicting-outputs

# Gere as localizações
flutter gen-l10n

# Execute em um dispositivo conectado
flutter run
```

### Executando os Testes

```bash
# Todos os testes
flutter test --no-pub

# Com cobertura
flutter test --no-pub --coverage
```

### Análise de Código

```bash
flutter analyze --no-fatal-infos
```

---

## Estrutura do Projeto

```
lib/
├── core/               # Constantes, extensões, hierarquia de falhas, tipos de resultado
├── domain/             # Entidades e interfaces de repositório
├── data/               # Modelos Isar, DAOs, serviço de banco de dados
├── infrastructure/     # Implementações de repositório, serviço de notificações
├── application/        # Gerenciamento de estado com BLoC/Cubit
├── presentation/       # Telas, widgets, navegação
└── config/             # Grafo de DI, configuração de l10n, roteador
```

---

## Roadmap

| Fase | Objetivo | Status |
|------|----------|--------|
| 01 | Fundação (scaffold, BD, DI, l10n, CI) | ✅ Concluído |
| 02 | Gerenciamento de Tarefas | 🔜 Próximo |
| 03 | Controle Financeiro | 🔜 Planejado |
| 04 | Notificações & Backup | 🔜 Planejado |
| 05 | Bloqueio do App (PIN + Biometria) | 🔜 Planejado |

---

## Contribuições

Este é um projeto pessoal. Issues e sugestões são bem-vindos via [GitHub Issues](https://github.com/lizzyman04/agenda/issues).

---

## Licença

MIT © [lizzyman04](https://github.com/lizzyman04)

---

<div align="center">

*Desenvolvido com Flutter — privado por design, poderoso por escolha.*

[Versão em inglês →](README.md)

</div>
