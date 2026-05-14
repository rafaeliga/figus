# Instruções para agentes de IA (Figus)

Conteúdo derivado do que o repositório já documenta: `README.md`, `pubspec.yaml` e `analysis_options.yaml`.

## O que é o projeto

App Flutter **pessoal** para gestão de figurinhas (começando pelo álbum Panini FIFA World Cup 2026). Bundle ID: `com.danielsampaio.figus`. Não é projeto corporativo Fhinck.

## Versões e toolchain

- **Dart:** `^3.6.0` (em `pubspec.yaml`, chave `environment.sdk`; exigido por `custom_lint` ≥0.7.1 / `pubspec_parse`).
- **Flutter:** `>=3.27.0` (em `pubspec.yaml`, chave `environment.flutter`; alinhado ao Dart 3.6).
- **asdf:** versão sugerida em `.tool-versions` (`flutter`) para alinhar ambientes; a fonte de verdade dos requisitos mínimos continua sendo o `pubspec.yaml`.
  - Na primeira vez (ou quando o pin mudar), na raiz do repo: `asdf install` (instala o Flutter da `.tool-versions`) e só então `flutter pub get`. Sem isso, o asdf pode acusar que nenhuma versão está definida ou o shim aponta para SDK antigo.

## Stack e pacotes principais

- **Estado:** `flutter_riverpod`, `riverpod_annotation` (+ codegen em dev).
- **Rotas:** `go_router`.
- **Persistência local:** `drift` (+ `drift_dev`, `build_runner` para gerar código).
- **UI:** Material, `google_fonts`, `flutter_svg`, etc. (ver dependências no `pubspec.yaml`).

## Estrutura de pastas (`lib/`)

- `core/theme/` — paleta e gradientes.
- `data/db/` — schema e migrations Drift.
- `data/seeds/` — seed das figurinhas.
- `data/repos/` — repositórios (ex.: Album, Collection, Profile).
- `data/providers.dart` — injeção / providers Riverpod.
- `domain/models/` — modelos para UI.
- `features/` — `album`, `stats`, `scan`, `profiles`, `settings`, `onboarding`.
- `app.dart` — `go_router`, shell, bottom nav.
- `main.dart` — bootstrap e seed.

## Comandos úteis para validar mudanças

- `flutter pub get`
- `dart run build_runner build` (após alterar Drift / Riverpod codegen quando aplicável)
- `flutter analyze`
- `flutter test`

## Análise estática (`analysis_options.yaml`)

- Base: `package:flutter_lints/flutter.yaml`.
- Excluídos do analyzer: `**/*.g.dart`, `**/*.freezed.dart`.
- `invalid_annotation_target`: ignorado.
- Regras extras: `prefer_single_quotes`, `sort_child_properties_last`, `use_key_in_widget_constructors`.

## Decisões e contexto já registrados no README

- Seed: 48 seleções (ordem alfabética até sorteio); jogadores podem ser placeholder até roster oficial Panini.
- **Scan/OCR:** dependências de câmera/OCR existem; comportamento completo ainda é roadmap — respeitar gates por plataforma (`Platform` / stubs onde já aplicável).
- Roadmap futuro (não misturar com escopo fechado sem pedido explícito): sync Supabase, import Figuritas, share refinado, crafting, etc.

## Orientação de escopo para alterações

- Preferir mudanças **focadas** no pedido; evitar refatorações amplas não solicitadas.
- Manter consistência com padrões existentes no código (nomes, Riverpod, Drift, rotas).
