# Figus

App pessoal de gestão de figurinhas — começando pelo álbum **Panini FIFA World Cup 2026**.

📲 **APK Android pronto:** [Release v0.1.0-alpha](https://github.com/sampaiodaniel/figus/releases/tag/v0.1.0-alpha) — baixe direto no celular e instale (precisa permitir "fontes desconhecidas").

> **Status:** alpha noturno. MVP da Noite 1 = núcleo funcional (980 figurinhas, marcação tem/falta/repetida, filtros, estatísticas, multi-perfil família, onboarding). OCR completo, importação Figuritas, share WhatsApp, sync e crafting chegam nas próximas noites conforme o plano em `~/.claude/plans/quero-fazer-um-app-parsed-hartmanis.md`.

## Como rodar (TESTE RÁPIDO — Chrome)

Tudo já está instalado e configurado em `C:\Dani_Dev\figus`. Flutter SDK em `C:\flutter`.

```powershell
cd C:\Dani_Dev\figus
.\start_app.ps1
```

Isso abre o Chrome em `http://localhost:8080` com o app rodando. Primeira execução ~30s pra compilar; subsequentes são instantâneas (hot reload).

### Validação feita na Noite 1
- ✅ `flutter pub get` — 22 deps OK
- ✅ `dart run build_runner build` — 115 outputs (drift) gerados
- ✅ `flutter analyze` — zero errors (só info-level lints sobre const)
- ✅ `flutter test` — **6/6 passando** (980 stickers, 48 nações × 20, FWC válido, foils, IDs únicos)
- ✅ `flutter build web --release` — 2.4MB main.dart.js
- ✅ `flutter run -d chrome` — compilou em 53s e abriu sem crashes

### Para testar em Android

Android SDK + Android Studio + JBR já estão configurados. APK release fica em
`build/app/outputs/flutter-apk/app-release.apk`. Pra rodar/buildar:

```powershell
# Variáveis de ambiente (já passadas pelos scripts)
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:ANDROID_HOME = 'C:\Android\Sdk'
$env:Path = "C:\flutter\bin;$env:JAVA_HOME\bin;C:\Android\Sdk\platform-tools;" + $env:Path

flutter devices                       # lista emuladores e celular USB
flutter run                           # debug com hot reload
flutter build apk --release           # APK pra instalar no celular
flutter build appbundle --release     # AAB pra Google Play Console
```

**Pra instalar no celular Android:**
1. Habilite "modo desenvolvedor" e "depuração USB" no celular
2. Conecte via cabo USB
3. `adb install -r build/app/outputs/flutter-apk/app-release.apk`
4. Ou copie o APK pra pasta Downloads do celular e instale tocando nele (precisa permitir "fontes desconhecidas")

### Para rodar / buildar no iOS (macOS)

Precisa de **Mac**, **Xcode** e **CocoaPods** (`sudo gem install cocoapods` ou via Homebrew). O bundle ID no iOS é o mesmo do Android: **`com.danielsampaio.figus`**.

**Primeira vez ou repo sem pasta `ios/`:**

```bash
cd figus
flutter create . --platforms=ios
flutter pub get
cd ios && pod install && cd ..
```

Abra **`ios/Runner.xcworkspace`** no Xcode (não o `.xcodeproj` sozinho), escolha um **Signing Team** no target Runner e rode no simulador ou no iPhone (`flutter run` com o device listado em `flutter devices`).

**Build release no device** (com assinatura configurada no Xcode):

```bash
flutter build ios
```

Para só validar compilação sem assinar: `flutter build ios --no-codesign`.

**Detalhes já aplicados neste projeto:**

- **iOS mínimo 15.5** — exigido pelo `google_mlkit_text_recognition` (Podfile + deployment target do Xcode).
- **`Info.plist`** — textos de uso para **câmera** (scan) e **biblioteca de fotos** (import); sem isso o sistema pode encerrar o app ao pedir permissão.
- **Ícone iOS** — em `pubspec.yaml`, `flutter_launcher_icons` está com `ios: false`; para gerar ícones nativos, ponha `ios: true` e rode `dart run flutter_launcher_icons`.

**Crash ao abrir pelo Xcode / mensagem tipo «Crash occurred when compiling … JIT mode»**

Em **iPhone físico** com **iOS recente** (ex.: 18.4+ ou betas mais novas), o modo **Debug** do Flutter usa JIT e o sistema pode negar alteração de memória executável (`mprotect`), o que derruba o Dart VM — sintoma comum no Xcode é crash ao compilar em JIT.

**Confirmado:** neste projeto, **`flutter run --release`** (ou Scheme **Release** no Xcode) no device físico **abre estável**; o problema some porque não há JIT.

- Rode no device em **Release** ou **Profile**: `flutter run --release` ou `flutter run --profile` (sem hot reload, mas estável).
- No Xcode: **Product → Scheme → Edit Scheme… → Run → Build Configuration → Release** (ou Profile).
- Para desenvolvimento com **hot reload**, use o **Simulador iOS** (JIT permitido) ou mantenha um Flutter **stable atualizado** (`flutter upgrade`), pois o ecossistema vai acompanhando mudanças da Apple.

Se o Flutter avisar que **`assets/seeds/`** não existe, crie a pasta vazia na raiz do projeto ou remova essa entrada do `pubspec.yaml` até haver arquivos lá.

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
