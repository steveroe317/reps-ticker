# Ticker Architecture

## Overview

Ticker is a focused exercise timer built for Hybrid Calisthenics-style 6-second slow reps
(2 s engage / 1 s pause / 2 s return / 1 s pause), with audio cues so the user does not need to
look at the screen. It has an iOS/iPadOS app and a watchOS app that share nearly all their code
through `Core/`.

Rest and stretch timers are being added on top of this structure; see `plans/add-timers.md`.

Toolchain: Swift 6 language mode, iOS 26 and watchOS 26, with MainActor default actor
isolation on both app targets.

---

## Project structure

```
Core/                        Shared by both app targets
  ActivitySession.swift      The one running activity: clock, schedule, cues, lifecycle
  Schedule.swift             An activity's timeline (lead-in + repeating or one-shot body)
  Schedules.swift            Schedule.reps(leadIn:)
  Segment.swift              A span of seconds with a label and cues
  SegmentPosition.swift      Offset / remaining / cycle within a segment
  ScheduleStep.swift         Label and cues for one second
  Cue.swift, Tone.swift      What should be heard
  CuePlaying.swift           Protocol for producing cues
  CuePlayer.swift            Produces cues: tones via SoundEffects, speech via AVSpeechSynthesizer
  SoundEffects.swift         Preloaded AVAudioPlayers, keyed by Tone
  Audio.swift                AVAudioPlayer.bundledWAV(named:)
  RuntimeHost.swift          Protocol: keep the app running for an activity
  PreviewRuntimeHost.swift   RuntimeHost for SwiftUI previews
  CoreContentView.swift      Idle screen, and the switch to RepCounterView
  RepCounterView.swift       Active screen: label, rep count, Stop
  StartCounting.swift        App Intent: start reps
  StopCounting.swift         App Intent: stop
  IntentMessages.swift       Counters the intents bump for the views to observe
Ticker/                      iOS target
  TickerApp.swift            Audio session setup; owns the ActivitySession
  IOSRuntimeHost.swift       Nothing to hold; 3 s lead-in
  ContentView.swift          Font sizes and background for iOS
Ticker Watch App/            watchOS target
  TickerApp.swift            TickerWatchApp: audio session setup; owns the ActivitySession
  WatchRuntimeHost.swift     Holds a WKExtendedRuntimeSession; 5 s lead-in
  ContentView.swift          Font sizes for watchOS
TickerTests/                 Swift Testing unit tests for schedules and the session
```

---

## How an activity runs

```
TickerApp ──owns──> ActivitySession ──asks──> Schedule        (pure data)
                         │       └──plays──> CuePlaying       (CuePlayer in the app)
                         └──holds──> RuntimeHost              (iOS / watchOS / preview)
Views ──read @Environment(ActivitySession.self)──> isActive, label, count, lastReps
```

- **One session per app.** Each `TickerApp` creates a single `ActivitySession` in `@State` and
  injects it with `.environment`. Views read it and call `startReps()` / `stop()`; they never
  own or create it, so re-rendering a view can never start or stop an activity.
- **Schedules are data.** A `Schedule` is a lead-in plus a body of `Segment`s. The body either
  repeats until stopped (`.cycle`, used for reps) or plays once and finishes (`.sequence`). The
  session asks `step(at:)` for the label and cues at each whole second, and
  `completedCycles(at:)` for the rep count. Stop and finish cues are part of the schedule.
- **Time comes from a monotonic clock.** Once the runtime host is ready, a `Task` sleeps until
  each next whole second on `ContinuousClock` and derives the current second from elapsed
  time, so a late wake-up never makes the activity lag. Each second's cues play once at most;
  a late tick skips missed cues rather than playing them late.
- **The model decides when it ends.** `stop()`, a non-repeating schedule reaching its end, or
  the platform ending the runtime (`onLost`) all go through one teardown that cancels the
  ticker, relinquishes the host, and flips `isActive`, which returns the UI to idle. Callbacks
  and ticks from an earlier run are ignored.
- **Intents** (`StartCounting`, `StopCounting`) bump counters in `IntentMessages`, which the
  idle and active views observe with `.onChange` and forward to the session. Starting while an
  activity runs does nothing.

### Rep schedule

`Schedule.reps(leadIn:)`:

| Second         | Label            | Cue                                  |
|----------------|------------------|--------------------------------------|
| 0 … leadIn − 1 | "Ready N" … "Ready 1" | "ready" at the first second     |
| +0, +1         | "Engage"         | the upcoming rep number, spoken, at +0 |
| +2             | "Pause"          | low tone (A3, 220 Hz)                |
| +3, +4         | "Back"           | high tone (A4, 440 Hz) at +3         |
| +5             | "Pause"          | low tone                             |

The 6-second body repeats; each completed pass is one rep. Stopping speaks "N completed" when
N > 0 and records N as Last Reps.

---

## Platform differences

| | iOS / iPadOS | watchOS |
|---|---|---|
| Runtime | `UIBackgroundModes: audio`; `IOSRuntimeHost` holds nothing | `WatchRuntimeHost` holds a `WKExtendedRuntimeSession` (`physical-therapy` background mode) for the whole activity |
| Lead-in | 3 s | 5 s, giving the speech synthesizer time to start |
| Timing starts | immediately | when the extended runtime session starts; the first second's label and "ready" are shown and spoken at once |
| Audio category | `.playAndRecord`, `.allowBluetoothA2DP` | `.playback`, `.allowBluetoothA2DP` |
| Fonts | 36 pt text, 90 pt symbol, brown background | 16 pt text, 36 pt symbol |

If watchOS ends the extended runtime session early, the session stops the activity as if the
user had pressed Stop.

Check speech timing on the watch without Xcode's debugger (uncheck Debug executable in the
scheme, or use a profiling build). With it attached, the first speech after launch can come
many seconds late and some labels are skipped while the speech frameworks load.

The watch Info.plist also lists `workout-processing` and the target carries a HealthKit
entitlement, though no HealthKit API is used; whether either is still needed is unresolved.

Both platforms set fonts with `Font.custom("SF Pro", size:)`, which opts out of Dynamic Type.
Replacing them is planned (R14 in `plans/add-timers.md`).

---

## Persistence

None. Last Reps lives in the session for the life of the process.

---

## Tests

`TickerTests` (Swift Testing) covers the rep schedule second by second against the original
cadence, `Schedule` sequencing and positions, and `ActivitySession`'s start, stop, skip,
lost-runtime, and stale-callback behavior using a fake host and a recording cue player. One
test runs the real clock for 3.5 s. The UI test targets and the watch test target are still
Xcode templates.
