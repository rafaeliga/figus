# Figus

App pessoal de gestão de figurinhas — começando pelo álbum **Panini FIFA World Cup 2026**.

> **Status:** alpha noturno. MVP da Noite 1 = núcleo funcional (980 figurinhas, marcação tem/falta/repetida, filtros, estatísticas, multi-perfil família, onboarding). OCR completo, importação Figuritas, share WhatsApp, sync e crafting chegam nas próximas noites conforme o plano em `~/.claude/plans/quero-fazer-um-app-parsed-hartmanis.md`.

## Como rodar (primeira vez)

### 1. Pré-requisitos
- **Flutter SDK** ≥ 3.24 — baixe do [site oficial](https://docs.flutter.dev/get-started/install) ou rode `setup_flutter.ps1` (descrito abaixo).
- **Android Studio** (com Android SDK + emulador) ou um celular Android com modo desenvolvedor + cabo USB.

### 2. Setup rápido (Windows PowerShell)
```powershell
# Na raiz do projeto:
cd C:\Dani_Dev\figus

# Gera os arquivos de plataforma (android/, ios/) sem mexer em lib/
flutter create . --project-name figus --org com.danielsampaio --platforms android

# Instala dependências
flutter pub get

# Gera código do drift (ORM)
dart run build_runner build --delete-conflicting-outputs

# Lista emuladores/devices
flutter devices
```

### 3. Rodar
```powershell
# Modo debug (hot reload)
flutter run

# Build APK pra instalar no celular
flutter build apk --debug
# APK vai pra build/app/outputs/flutter-apk/app-debug.apk
```

## O que está pronto na Noite 1

- ✅ 980 figurinhas seedadas (FWC + 48 seleções × 20)
- ✅ Layout estilo álbum: cards retangulares verticais, gradient vibrante quando tem, cinza quando falta
- ✅ Tap (tenho) / tap de novo (repetida +1) / long press (remove)
- ✅ Tabs: Todas / Me faltam / Repetidas + busca
- ✅ Agrupamento colapsável por seleção com contador X/20
- ✅ Tela de estatísticas (% completo, total, faltam, tenho, repetidas, brilhantes X/49)
- ✅ Multi-perfil família local (criar/trocar perfis no mesmo aparelho)
- ✅ Onboarding 3 telas
- ✅ Bottom nav (Álbum · Estatísticas · Trocar · Config)
- ✅ Foil shimmer nos brilhantes (49 stickers especiais)

## O que vem nas próximas noites

- 🔜 OCR completo de página (warp + glare removal + multi-frame + album-lock)
- 🔜 Importação 1-clique do Figuritas (PDF + OCR de screenshot)
- 🔜 Compartilhamento WhatsApp com card OG visual
- 🔜 Sync multi-device no mesmo perfil (Supabase, last-write-wins por campo)
- 🔜 Crafting: forjar 5 repetidas em 1 que falta
- 🔜 Wishlist com prioridade
- 🔜 Tema premium R$9,90 lifetime

## Estrutura

```
lib/
  core/theme/          — paleta, gradients
  data/
    db/                — schema drift, migrations
    seeds/             — seed dos 980 stickers
    repos/             — AlbumRepo, CollectionRepo, ProfileRepo
    providers.dart     — DI riverpod
  domain/models/       — DTOs UI (StickerView, AlbumStats, …)
  features/
    album/             — tela principal + cards
    stats/             — dashboard
    scan/              — OCR (stub na Noite 1)
    profiles/          — multi-perfil
    settings/          — config
    onboarding/        — 3 slides iniciais
  app.dart             — go_router + shell + bottom nav
  main.dart            — bootstrap + seed
```

## Decisões já tomadas

Ver `~/.claude/plans/quero-fazer-um-app-parsed-hartmanis.md` (seção "Decisões pré-aprovadas para execução autônoma noturna") — incluindo:

- Bundle ID: `com.danielsampaio.figus` (projeto **pessoal**, não Fhinck)
- Stack: Flutter + drift + riverpod + go_router
- Seed: 48 seleções alfabéticas até sair sorteio (dez/2025)
- Jogadores: placeholder ("Jogador BRA 1") até Panini publicar rosters

## Próximas decisões que precisam de input

1. Substituir ícone/splash placeholder
2. Criar conta Supabase (sync)
3. Criar conta Google Play Console (R$130 única vez) e Apple Developer (US$99/ano)
4. Repo git remoto pessoal pra `git push`
