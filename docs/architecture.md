# Reps-Ticker Architecture

## Overview

Reps-Ticker is a focused, single-purpose fitness timer built for Hybrid Calisthenics-style exercise — specifically 6-second slow reps (2s engage / 1s pause / 2s return / 1s pause). It has two targets: an iOS app and a watchOS app, sharing substantial code via a `Core/` folder.

---

## Project Structure

```
Ticker.xcodeproj
├── Core/                     # Shared between iOS and watchOS
│   ├── Phase.swift           # Exercise phase state machine
│   ├── CoreContentView.swift # Primary shared UI
│   ├── RepCounterView.swift  # Active rep-counting UI
│   ├── Audio.swift           # AVAudioPlayer wrapper
│   └── SoundEffects.swift    # Tone management
├── Ticker/                   # iOS target
│   ├── TickerApp.swift
│   ├── ContentView.swift
│   └── ContentModel.swift
└── Ticker Watch App/         # watchOS target
    ├── TickerApp.swift
    ├── ContentView.swift
    └── ContentModel.swift
```

---

## Architecture

The app uses an MVVM-style pattern with minimal indirection:

- **Model layer:** `Phase` — a value-type state machine representing where in the rep cycle the user is (phases -3 through 5, with negative values being a pre-start countdown).
- **View model:** `ContentModel` — an `@Observable` class (one per platform) that owns the timer, rep count, phase, and audio. It is the single source of truth for a session.
- **Views:** `CoreContentView` and `RepCounterView` are shared. Each platform wraps them in its own thin `ContentView` (mostly for font size tuning).

Navigation is simple boolean-gate logic: a single `repCounterActive` flag switches between the idle UI and the active rep-counter.

There is **no persistence** — the session is stateless. Rep history is not saved.

---

## Apple Frameworks

| Framework | Usage |
|---|---|
| **SwiftUI** | All UI on both platforms |
| **AVFoundation** | `AVAudioPlayer` for tones (220 Hz / 440 Hz), `AVSpeechSynthesizer` for spoken rep counts, `AVAudioSession` for audio routing |
| **WatchKit** | `WKExtendedRuntimeSession` on watchOS to keep the app alive during a workout |
| **Foundation** | `Timer` for the per-second tick, `Bundle` for audio file loading |

HealthKit entitlements are declared in the watchOS target but no HealthKit APIs are called — the entitlement appears to be required for the `workout-processing` background mode.

---

## iOS vs watchOS: Key Differences

### Timer / Background Execution

| | iOS | watchOS |
|---|---|---|
| Timer mechanism | `Timer` added to `.common` RunLoop | `Timer` added to `.common` RunLoop, wrapped inside a `WKExtendedRuntimeSession` |
| Background support | `UIBackgroundModes: audio` in Info.plist | `WKBackgroundModes: workout-processing, physical-therapy` + HealthKit entitlement |

The watchOS `ContentModel` conforms to `WKExtendedRuntimeSessionDelegate` and starts an extended runtime session when the timer starts, stopping it when the timer stops. Without this, watchOS would suspend the app mid-workout.

### Audio Session Category

| | iOS | watchOS |
|---|---|---|
| Category | `.playAndRecord` | `.playback` |
| Options | `.allowBluetoothA2DP` | `.allowBluetoothA2DP` |

iOS uses `.playAndRecord` for microphone-route compatibility; watchOS uses the simpler `.playback`.

### UI / Font Sizing

Both platforms use the same `CoreContentView` and `RepCounterView`, but each platform's `ContentView` injects a different font size via environment:

| | iOS | watchOS |
|---|---|---|
| `.font` env value | `.system(size: 36)` | `.system(size: 16)` |
| Image font size | 90pt | 36pt |

The iOS `ContentView` also applies a brown tint background at 0.5 opacity; the watchOS `ContentView` does not.

### Known Duplication

`ContentModel` is duplicated between targets. The timer setup and audio session configuration differ enough per platform that sharing requires a protocol abstraction or conditional compilation — a refactor not yet done.

---

## Audio Design

Two complementary audio channels run in parallel during a rep:

1. **Tones** — A3 (220 Hz) at engage, A4 (440 Hz) at the return and at rep completion
2. **Speech** — `AVSpeechSynthesizer` speaks "ready" during the countdown and the rep number aloud at each completion

This gives the user both tactile (audio cue) and informational (count) feedback without needing to look at the screen — important for both phone-in-pocket iOS use and wrist-glance watchOS use.

---

## Exercise Phase State Machine

`Phase` cycles through 9 states per rep, encoded as an integer:

| Phase value | Label | Duration |
|---|---|---|
| -3, -2, -1 | Pre-start countdown | 1s each |
| 0, 1 | Engage (concentric) | 2s |
| 2 | Pause after engage | 1s |
| 3, 4 | Return (eccentric) | 2s |
| 5 | Pause after return | 1s, then cycle repeats |

`Phase.advance()` increments the value and wraps back to 0 after phase 5, triggering a rep count increment via `CycleCompleted()`.
