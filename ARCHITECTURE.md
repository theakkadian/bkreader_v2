# BET KANU Reader — Architecture

Clean Architecture + **flutter_bloc** rewrite of the Capni / BET KANU companion app for printed Syriac books.

## Layers

```
presentation  →  domain  ←  data
     ↑              ↑
   blocs         entities
   pages         use cases
   widgets       repository ports
```

| Layer | May import | Must not import |
|-------|------------|-----------------|
| `domain/` | Dart + equatable | Flutter, http, flutter_bloc, UI packages |
| `data/` | domain, http, xml2json | BuildContext, blocs, Provider |
| `presentation/` | domain via blocs → use cases | datasources directly |

## Features

### `scan`
- **ScanBloc** — event pipeline: camera QR → resolve → fetch → load text
- Events: `ScanStarted`, `QrDetected`, `ScanCancelled`, `ScanReset`
- States: `ScanInitial`, `ScanDetecting`, `ScanResolving`, `ScanSuccess`, `ScanFailure`
- Debounces duplicate QR values; only one resolve in flight; cancels HTTP on leave

### `reader`
- **ReaderBloc** — typed `BookContent` session, remote audio via `AudioPlayerPort`
- Events: `LoadContent`, `PlayAudio`, `PauseAudio`, `StopAudio`, `ToggleZoom`, `ShowReaderFailure`, `ClearReader`
- States: `ReaderInitial`, `ReaderLoading`, `ReaderReady`, `ReaderPlaying`, `ReaderError`
- Pauses audio when the app backgrounds

### `connectivity`
- **ConnectivityCubit** — `Online` / `Offline` from `connectivity_plus`
- Snackbars only after the first real *change* (no “entered app” hack)

### `about`
- Static credits / share / rate / instructions (mostly presentational)

## QR resolution (preserve printed-book quirks)

1. `NormalizeQrUrlUseCase` — **all** legacy URL/typo fixes live here (missing `.com`, `kidssongsbookk`, `zmryothedzaaorebook`, CRLF). Unit tested.
2. `ResolveQrUseCase` → `YoutubeTarget` | `XmlTarget` | `BetKanuApiTarget` | `InvalidTarget`
3. `FetchBookContentUseCase` + `LoadBookTextUseCase` → typed `BookContent`

API: `GET https://www.betkanu.com/api/BKReader` with header `FROM: BETKANU`.  
XML: Parker transform → `BKRBundle` fields.  
String `"null"` from API/XML is treated as absent (`nullIfBlankOrNullString`).

## Navigation (`go_router`)

| Route | Purpose |
|-------|---------|
| `/home` | Intro logo or reader card + scan/play/about chrome |
| `/scan` | Camera scanner (permission gated) |
| `/reader` | Redirects to `/home` (content held in `ReaderBloc`) |
| `/about` | Credits / social / share / rate |
| `/instructions` | App usage steps |

## DI (`get_it`)

Registered in `lib/core/di/injection.dart`: HTTP wrapper, datasources, `BookRepository`, use cases, TTS/AI stubs, bloc factories.

## Shared ports

| Port | Role |
|------|------|
| `AudioPlayerPort` / `JustAudioAdapter` | Intro SFX, scan SFX, content audio |
| `UrlLauncherPort` | External YouTube opens (no raw `url_launcher` in blocs) |
| `TtsPort` | Future Syriac/companion speech |
| `AiAssistantPort` | Future explain / transliterate / quiz |
| `AutoReadCoordinator` | Stub composing session text + `TtsPort` |
| `ReaderSession` | Content id, texts, audio URL, position |

## Plugging real TTS / AI later (no bloc rewrite)

1. Implement `TtsPort` (e.g. platform channel or cloud TTS) and register it in `configureDependencies()` instead of `FakeTtsPort`.
2. Implement `AiAssistantPort` similarly; expose UI actions that call use cases wrapping the port.
3. Wire `AutoReadCoordinator.start(session)` from a new `ReaderEvent` (e.g. `StartAutoRead`) — blocs already depend on ports/use cases, not concrete engines.
4. Persist `ReaderSession.position` when you add progress tracking.

## State management rules

- **flutter_bloc only** for feature state
- `setState` only for ephemeral UI glue (e.g. `AnimationController` / video slider)
- No god bloc — scan, reader, and connectivity are separate

## Error model

`NetworkFailure`, `QrParseFailure`, `ApiFailure`, `MediaFailure`, `PermissionFailure`, `TextLoadFailure` — mapped to user-facing copy in presentation.
