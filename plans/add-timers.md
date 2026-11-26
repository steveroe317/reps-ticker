# Plan: Rest and Stretch Timers

Status: **Phase 0 done** (`5c8f772`). **Phase 1 done** on branch `phase-1-sequencer`,
checked on iPhone and watch. Next: Phase 2. Last updated 2026-11-25.

## Goal

Add two new timed activities alongside the existing rep counter:

1. **Rest** — time the rest between sets within a workout. Up to 5 minutes, audio every 30 seconds.
2. **Stretch** — time a two-sided stretch routine, reusing the same timing facility.

"Sessions" in the original request means **sets within one workout**, not whole workouts.

All three activities, plus Stop, must be invocable by **Siri with no user setup** on both
iPhone and Watch. The core hands-free flow is: finish a set → "Hey Siri, rest with Ticker" →
the set is recorded and rest starts.

## Resolved behavior

### Rest

Started manually (idle screen, reps screen, or Siri). Single 5:00 segment, spoken **elapsed**
time (counting up) every 30 seconds, auto-terminates at the cap. No lead-in: rest has already
begun when you ask for it, so elapsed time starts at 0:00 immediately.

```
0:00  "rest"
0:30  "thirty seconds"
1:00  "one minute"
1:30  "one minute thirty"
...
4:30  "four minutes thirty"
5:00  "rest finished"      -> returns to idle
```

The 5:00 cue is terminal: it announces `"rest finished"` instead of `"five minutes"`.
Pressing Stop at any point returns to idle silently. There is no duration picker and no
stored rest duration — the expectation is that you stop it when you are ready to go again,
and 5:00 is a timeout rather than a target.

The 0:00 `"rest"` cue may be lost to Siri's own reply when started by voice, or to speech
warm-up on the watch. That is acceptable; the screen and the 0:30 cue confirm it is running.

### Stretch

Hold length `N` is 15, 30, or 60 seconds. Three rounds, a lead-in before **every** side,
no trailing rest after the third round.

```
Round 1:  Ready 3 · Left N · Ready 3 · Right N · Rest 30
Round 2:  Ready 3 · Left N · Ready 3 · Right N · Rest 30
Round 3:  Ready 3 · Left N · Ready 3 · Right N  ->  "stretch finished"
```

| N  | total | watch total (5 s first lead-in) |
|----|-------|---------------------------------|
| 15 | 2:48  | 2:50                            |
| 30 | 4:18  | 4:20                            |
| 60 | 7:18  | 7:20                            |

Cues within a round, taking N=60:

```
"left"   ->  3 s to reposition  ->  high tone (hold starts)
         0:30  "thirty seconds"        (N=60 only)
         0:57  "three" "two" "one"
"right"  ->  3 s  ->  high tone  ->  ...
```

- The side name is announced at the **start of the Ready segment** — it means "start
  repositioning".
- A high tone (`A4-440Hz.wav`) marks the **start of the hold**. Without it the Ready segment
  has no audible end. No new audio assets are needed.
- The mid-hold elapsed mark fires only for N=60; a 15 s or 30 s hold gets the start cue and
  the 3-2-1 countdown only.
- The stretch's internal 30 s rests get a `"rest"` start cue and no mid-announcements — one
  at 0:30 would land on the segment boundary anyway.
- One hold length per routine; it applies to all three rounds.
- `N` is remembered (`@AppStorage`, per device) and used when Stretch is started without an
  explicit hold, including by Siri.

### Watch haptics

The watch taps alongside the audio, because a tap is more reliable than audio under a sleeve.

| moment                         | haptic (`WKHapticType`) |
|--------------------------------|-------------------------|
| side announced (Ready starts)  | `.directionUp`          |
| hold starts (with high tone)   | `.start`                |
| `"stretch finished"`           | `.success`              |
| `"rest finished"` (rest timer) | `.success`              |

Reps get no haptics (a tap every 1–2 s would be noise). iOS ignores haptic cues.

### Reps

Unchanged, including the ready countdown, the 2-1-2-1 cadence, the tone/number cues, and the
`"N completed"` announcement on stop. The reps screen gains a **Rest** button beside Stop
(see hand-off).

### Activity hand-off

Starting an activity while another is running never silently fails:

| running ↓ / requested → | Reps            | Rest                     | Stretch                  |
|-------------------------|-----------------|--------------------------|--------------------------|
| idle                    | start           | start                    | start                    |
| reps                    | no-op           | finish reps → start rest | finish reps → start stretch |
| rest                    | stop → start reps | restart rest from 0:00 | stop → start stretch     |
| stretch                 | stop → start reps | stop → start rest      | restart stretch          |

"Finish reps" means exactly what Stop does today: record the count as Last Reps and speak
`"N completed"`. The new activity's start cue queues behind it. Stopping rest or stretch is
silent. A hand-off keeps the platform runtime session held throughout — it is not released
and reacquired (see `RuntimeHost`).

The rest → reps row makes the reverse leg hands-free too ("start Ticker" during rest), without
committing to automatic chaining (still rejected, see Open / deferred).

### Audio

- Other audio (music, podcasts) keeps playing and is **ducked** while cues play.
- iOS moves from `.playAndRecord` to `.playback` with `.duckOthers`; watchOS adds
  `.duckOthers` to its existing `.playback`. (`.playAndRecord` without `.defaultToSpeaker`
  routes iPhone output to the receiver — load-bearing once the phone is on the floor.)
- Ducking is held while cues are dense and released while they are sparse: `CuePlayer`
  deactivates the session with `.notifyOthersOnDeactivation` when no cue is due within ~2 s,
  and reactivates before the next one. Reps therefore hold the duck for the whole set; rest
  and stretch holds release it between cues.
- Audio session configuration moves out of `TickerApp.init` into `ActivitySession.start()`,
  so an intent-launched activity cannot begin before audio is configured.

### iPhone screen

While any activity runs, the iPhone does not auto-lock (`isIdleTimerDisabled`, set in
`IOSRuntimeHost.acquire` / cleared in `release`). Reason: with the `audio` background mode iOS
only keeps the app alive while sound is actually playing, and rest and 60 s stretch holds have
27–30 s silent gaps, so a locked phone would likely suspend mid-rest and skip cues. A **manual**
lock will still suspend it — documented behavior, not a bug. Verify on device during Phase 2.

### Siri

There is no Siri support today beyond the Shortcuts app: `StartCounting` / `StopCounting` are
bare `AppIntent`s with no `AppShortcutsProvider`, so Siri needs a hand-built Shortcut. Add
App Shortcuts so every activity has built-in phrases on iPhone and Watch:

```swift
struct TickerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartCounting(),
                    phrases: ["Start \(.applicationName)", "Count reps with \(.applicationName)"],
                    shortTitle: "Start Reps", systemImageName: "figure.core.training")
        AppShortcut(intent: StartRest(),
                    phrases: ["Rest with \(.applicationName)", "Start \(.applicationName) rest"],
                    shortTitle: "Rest", systemImageName: "timer")
        AppShortcut(intent: StartStretch(),
                    phrases: ["Stretch with \(.applicationName)",
                              "Stretch \(\.$hold) with \(.applicationName)"],
                    shortTitle: "Stretch", systemImageName: "figure.flexibility")
        AppShortcut(intent: StopCounting(),
                    phrases: ["Stop \(.applicationName)"],
                    shortTitle: "Stop", systemImageName: "stop.circle")
    }
}
```

- **Hold must be an `AppEnum`**, not `Int`: App Shortcut phrases can only interpolate
  `AppEnum` / `AppEntity` parameters. `StretchHold: Int, AppEnum { fifteen = 15, thirty = 30,
  sixty = 60 }` with display representations "15 seconds" etc. `StartStretch.hold` is
  optional; `nil` uses the remembered N.
- **Keep the type names `StartCounting` and `StopCounting`** so users' existing Shortcuts keep
  working. Retitle them ("Start Reps", "Stop Ticker") but do not rename the structs.
  `StopCounting` stops **any** activity.
- **Start intents keep `openAppWhenRun = true`.** On watchOS a `WKExtendedRuntimeSession` can
  only be started while the app is active, and on iOS the keep-awake decision assumes the app
  is on screen. `StopCounting` stays `openAppWhenRun = false`.
- Intents reach the session through `@Dependency` (registered with `AppDependencyManager` in
  each `TickerApp.init`), not a message bus. Verify watchOS availability with
  `DocumentationSearch`.
- Intents return `.result()` with no dialog; the app's own cues are the feedback. Siri's reply
  may overlap the first cue — the 3 s / 5 s Ready lead-in absorbs this for reps and stretch.
- Phrases include `\(.applicationName)` as App Shortcuts require. Check the display name
  (Ticker vs. RepsTicker) and add `INAlternativeAppNames` if both should work.

## Why this needs refactoring first

The feature looks small but collides with four assumptions in the current code.

**1. The cadence is code, not data.** `CounterSessionBase.makeCounterTimer()`
(`Core/CounterSessionBase.swift:29`) is simultaneously the clock, the schedule, the rep
counter, and the cue dispatcher. `Phase` (`Core/Phase.swift:11`) hardcodes the 6-tick wrap
(`value < 5`) and exposes four fixed predicates that exist only to feed that one
`if/else-if` chain. There is no seam for a different schedule.

**2. Nothing can end an activity except the user.** Termination is view-driven:
`RepCounterView.endCounting()` (`Core/RepCounterView.swift:35`) writes the count out, stops
the model, and flips the parent's binding. The model has no way to say "I am done". A rest
timer must end itself, so this control inversion is the single biggest change the feature
forces.

**3. The session is constructed as a side effect of view initialization.**
`@State var model = CounterSession()` (`Core/RepCounterView.swift:17`), where
`CounterSession.init` starts the timer and `deinit` stops it
(`Ticker/CounterSession.swift:18-25`).

`State.init(wrappedValue:)` is not an autoclosure — unlike `StateObject`'s — so
`CounterSession()` is evaluated on **every** `RepCounterView` struct initialization. SwiftUI
keeps the first box and discards the rest; each discarded instance deinits and calls
`stopCounting()`, which invalidates the live `sharedTimer.timer`. (The live instance itself
never deinits while running: its timer closure retains it strongly.) Today `CoreContentView`
happens not to re-render while an activity runs, so this is latent. The moment the parent
holds rest/stretch state (mode, remaining time, round number) it **will** re-render
mid-activity and the running timer will die — silently, because `startCounting()`'s
`guard sharedTimer.timer == nil else { return }` early-returns with no timer and no error.
On the watch it is worse: each discarded instance also starts a second
`WKExtendedRuntimeSession` before being thrown away.

**4. `TimerSingleton` turns a hand-off into a silent failure.** That same guard means a new
activity constructed before the previous timer is invalidated does nothing at all: no timer,
no cues, no complaint. The hand-off table above makes this case routine.

## Target architecture

Three concerns that are currently fused:

```
Clock + platform runtime   ->  ActivitySession  (one, long-lived, @MainActor)
Schedule + labels + cues   ->  Schedule         (data, per activity)
Sound / haptic production  ->  CuePlayer
```

### The segment sequencer

As built in Phase 1:

```swift
enum Cue { case tone(Tone), speak(String) }      // .haptic(Haptic) arrives in Phase 3

struct SegmentPosition { let offset, remaining, cycle: Int }

struct Segment {
    let duration: Int
    let label: (SegmentPosition) -> String      // "Ready \(remaining)" / "Engage" / "Rest"
    let cues: (SegmentPosition) -> [Cue]        // offset 0 = start; 30 s marks and 3-2-1 too
    init(duration:label:startCues:)             // convenience: fixed label, cues at start
}

struct Schedule {
    let leadIn: [Segment]                       // played once
    let body: [Segment]                         // repeated, or played once then finish
    let repeats: Bool
    let stopCues: (_ completedCycles: Int) -> [Cue]   // reps: "N completed"
    let finishCues: [Cue]                             // rest: "rest finished"
    static func cycle(leadIn:body:stopCues:) -> Schedule      // reps
    static func sequence(_:finishCues:) -> Schedule           // rest, stretch
    func step(at second: Int) -> ScheduleStep?   // label + cues; nil once a sequence ends
    func completedCycles(at second: Int) -> Int
}
```

A struct rather than the enum first sketched: reps need a lead-in that does not repeat, and
stop and finish cues belong to the activity rather than the session. `SegmentPosition.cycle`
is what lets the Engage segment speak the upcoming rep number.

Cues are arrays because a moment can carry several (speech + haptic). Silence is `[]`.

The reason this is the right primitive: **the existing rep cadence is already exactly "one
cue per segment boundary."** Phase 0 speaks the number, 2 is a low tone, 3 a high tone, 5 a
low tone (`Core/CounterSessionBase.swift:35-43`). Those four cue points *are* four segment
entries:

```swift
.cycle([ Engage(2, speak next rep #), Pause(1, low), Back(2, high), Pause(1, low) ])
```

So reps port over with no behavior change, and `Phase`'s `-3…5` integer machine is deleted
rather than generalized. Two things dissolve into the model for free:

- The ready countdown becomes a plain `Ready(3)` segment, and the watch's speech-warm-up hack
  `phase.setPhase(phaseValue: -5)` (`Ticker Watch App/CounterSession.swift:23`) becomes
  `Ready(5)` supplied per platform.
- "A few seconds to get into the stretch position" is the *same* `Ready` segment reused — no
  new concept.

### Schedules as data

```swift
extension Schedule {
    static func reps(leadIn: Int) -> Schedule                         // Phase 1
    static func rest() -> Schedule                                    // one 300 s segment, no lead-in
    static func stretch(hold: StretchHold, leadIn: Int) -> Schedule   // fully expanded, 3 rounds
}
```

Static members, so call sites read `session.start(.rest())`. They are pure, which makes them
directly unit-testable.

### Session and runtime

`ActivitySession` is `@MainActor @Observable`. It holds the current schedule, a start
instant, and a high-water cue index, and exposes `start(_:)`, `stop()`, `label`, `detail`,
`isActive`, and `lastReps`. `start(_:)` implements the hand-off table. `cycle` counts
completions as reps; `sequence` finishes at the end and tears itself down.

Position is derived from **elapsed time on `ContinuousClock`, not accumulated ticks** (and not
`Date`, which jumps with clock changes). Over 6 seconds tick drift is invisible, but over
5–7 minutes a delayed or coalesced tick permanently lags, and 30-second cue boundaries would
drift off. Elapsed-time derivation plus the cue high-water mark also makes a missed tick skip
a cue rather than fall behind forever. The driver is a `Task` that sleeps until each next
whole second (`Task.sleep(until:clock:)`), replacing `Timer` and `RunLoop`.

`CuePlaying` and `RuntimeHost` are injected so `ActivitySession` is testable with fakes;
tests drive time with the internal `advance(to:)` instead of injecting a clock, because a fake
host that never reports ready keeps the real clock from starting. A run counter makes
callbacks and ticks from an earlier run no-ops.

`RuntimeHost` abstracts the platform lifetime: `leadIn`, `acquire(onReady:onLost:)`, and
`relinquish()` (not `release()`, which `NSObject` reserves). `onLost` lets the platform end
an activity, which stops it like the user pressing Stop. iOS calls back immediately (and from
Phase 2 disables auto-lock); watchOS starts a `WKExtendedRuntimeSession` and calls
back from `extendedRuntimeSessionDidStart`. One runtime session per **run of activities**,
never per segment — a 7:18 stretch routine with internal rests, or a reps → rest hand-off,
holds a single session throughout. The extended runtime session this code starts runs under
the `physical-therapy` background mode (up to 1 hour); `workout-processing` applies to
`HKWorkoutSession`, which the app does not use. Churning sessions risks watchOS
rate-limiting a start.

## File layout

```
Core/
  Cue.swift              NEW     Cue                                  (Phase 1)
  Tone.swift             NEW     Tone, with its file name             (Phase 1)
  Haptic.swift           NEW     Haptic                               (Phase 3)
  CuePlaying.swift       NEW     protocol, for test fakes             (Phase 1)
  CuePlayer.swift        NEW     owns SoundEffects + AVSpeechSynthesizer (Phase 1); ducking
                                 window (Phase 4); watch haptics via WKInterfaceDevice (Phase 3)
  Segment.swift          NEW     Segment                              (Phase 1)
  SegmentPosition.swift  NEW     offset / remaining / cycle           (Phase 1)
  Schedule.swift         NEW     Schedule                             (Phase 1)
  ScheduleStep.swift     NEW     label + cues for one second          (Phase 1)
  Schedules.swift        NEW     Schedule.reps (Phase 1) / .rest / .stretch
  PreviewRuntimeHost.swift NEW   RuntimeHost for SwiftUI previews     (Phase 1)
  StretchHold.swift      NEW     AppEnum 15 / 30 / 60
  ActivitySession.swift  NEW     sequencer + clock + hand-off + lifecycle (was CounterSessionBase)
  RuntimeHost.swift      NEW     protocol leadIn / acquire(onReady:onLost:) / relinquish()
  ActivityView.swift     RENAME  was RepCounterView — generic label / detail / Stop (+ Rest for reps)
  CoreContentView.swift  CHANGE  idle: Start / Rest / Stretch + remembered N selector
  SoundEffects.swift     KEEP
  Audio.swift            CHANGE  fix the force-unwrap at Audio.swift:16 while nearby
  StartCounting.swift    CHANGE  keep type name; retitle; call the session via @Dependency
  StopCounting.swift     CHANGE  keep type name; retitle; stops any activity
  StartRest.swift        NEW     AppIntent
  StartStretch.swift     NEW     AppIntent, optional hold: StretchHold
  TickerShortcuts.swift  NEW     AppShortcutsProvider (both targets)
  Phase.swift            DELETE  -> Segment + Schedule
  TimerSingleton.swift   DELETE  -> one session makes it structurally unnecessary
  CounterSessionBase.swift DELETE -> ActivitySession
  IntentMessages.swift   DELETE  -> intents reach the session directly

Ticker/
  IOSRuntimeHost.swift   RENAME  was CounterSession.swift; also owns keep-awake
  TickerApp.swift        CHANGE  create session, register with AppDependencyManager, inject

Ticker Watch App/
  WatchRuntimeHost.swift RENAME  was CounterSession.swift
  TickerApp.swift        CHANGE  create session, register with AppDependencyManager, inject
```

### Display per activity

| activity | `label`                                 | `detail`              | buttons      |
|----------|-----------------------------------------|-----------------------|--------------|
| reps     | "Ready 3" / "Engage" / "Pause" / "Back" | "Reps: 7"             | Stop · Rest  |
| rest     | "Rest"                                  | "1:30" (elapsed)      | Stop         |
| stretch  | "Ready 3" / "Left" / "Right" / "Rest"   | "Round 2 of 3"        | Stop         |

Elapsed time is formatted with `Duration.formatted(.time(pattern: .minuteSecond))`. On the
watch the idle screen's three buttons plus the 15·30·60 selector must fit at the default
font size — prefer a compact picker (or a menu on the Stretch button) over a fourth row.

## Refactorings

R-numbers are referenced by the phase list below.

| #   | Refactoring | Why |
|-----|-------------|-----|
| R0  | Toolchain: iOS 26 / watchOS 26 deployment targets, Swift 6 language mode, MainActor default isolation, approachable concurrency. | AGENTS.md targets; the new code is written once, in its final dialect. |
| R1  | Hoist session ownership out of the view. One `ActivitySession` created in each `TickerApp`, injected via `.environment` and registered with `AppDependencyManager`. Views render it, never own it. | Kills problem 3 and the `deinit`-based teardown. Prerequisite for everything else. |
| R2  | Delete `TimerSingleton`. | Kills problem 4; with one session the dedup guard is structurally impossible to need. |
| R3  | Extract `Cue` + `CuePlayer`. | Lets a schedule declare *what* should be heard without knowing how. Home for ducking and watch haptics. |
| R4  | Replace `Phase` and the tick handler with the `Segment`/`Schedule` sequencer; port reps to `repSchedule`. | The feature. Deletes more than it adds. |
| R5  | Model-driven completion: `isFinished` -> session teardown -> observable change -> view returns to idle. | Problem 2. Rest and stretch end themselves. |
| R6  | Split platform runtime into `RuntimeHost`; collapse the two `CounterSession.swift` files into one shared session. | Removes duplicated start/stop/teardown; lets one runtime session span a whole run of activities. |
| R7  | Derive position from elapsed `ContinuousClock` time rather than accumulated ticks; `Task` driver replaces `Timer`. | 30-second cue boundaries over 5–7 minutes; graceful recovery from a missed tick. |
| R8  | *(dissolved)* | Configurable lead-in became a `Ready` segment. |
| R9  | Generalize the activity view: rename to `ActivityView`, replace `Text("Reps: \(model.count)")` with `session.detail`, drop the `counting`/`repCount` bindings in favour of reading the session. | "Reps: N" is meaningless for a stretch. |
| R10 | Collapse `IntentMessages`; intents call the session via `@Dependency`; add parameterized intents. | The counter-bump + `.onChange` dance exists *only* because the session lives inside the view. An `Int` bump also cannot carry `StartStretch(hold:)`'s payload. |
| R11 | Idle-screen activity chooser: Start / Rest / Stretch with a remembered N and a 15·30·60 selector. | One tap in the common case where the same N is always used. |
| R12 | Hand-off in `ActivitySession.start(_:)` per the table; Rest button on the reps screen. | The core hands-free flow; also makes problem 4's scenario well-defined. |
| R13 | App Shortcuts provider with Siri phrases; `StretchHold` `AppEnum`. | Siri with no user setup. |

Also noted:

- Cue strings need a terseness budget: `AVSpeechSynthesizer.speak` queues rather than
  interrupts, so an utterance longer than its 3 s `Ready` window bleeds into the hold. The
  hand-off's `"N completed"` + next start cue is the longest queue; check it on device.
- The watch Info.plist's Health usage strings claim HealthKit is used "to play audio in the
  background", and the entitlement is present with no access types. Not touched by this plan,
  but worth confirming it is still needed before the next App Review submission.

## Prior review and architecture doc

`docs/code-reviews/2026-04-09.md` and `docs/architecture.md` were written against an older
tree (`ContentModel`, before `CounterSessionBase` existed). Status of each review finding:

| Review finding | Status |
|----------------|--------|
| `@Observable` classes missing `@MainActor` | Fixed in Phase 0 (MainActor default isolation). |
| Timer callback copy-pasted between targets | Already fixed by `CounterSessionBase`. |
| `init()` starts the timer; `RepCounterView` depends on a per-target type; `repCount` owned by the wrong view | R1 + R6 + R9. |
| Timer closure retain cycle | R7: the `Task` driver is cancelled in `stop()` and on finish; the session lives for the app's lifetime, so a strong capture is safe. |
| `Phase` magic numbers, `CycleCompleted()` naming, flag-based completion | R4 deletes `Phase`. |
| Magic sound-key strings; `[String: AVAudioPlayer?]` double optional; free `makeAudioPlayer` | R3: `Tone` enum keys `CuePlayer`'s players; build `[Tone: AVAudioPlayer]` with nils filtered out. |
| `Audio.swift` force unwrap | R3, via `Bundle.main.url(forResource:withExtension:)`. |
| Watch `session` implicitly unwrapped; `if timer != nil { …timer! }` | R6 (`WatchRuntimeHost` holds an optional); the timer code is deleted. |
| iOS session inherits `NSObject` without reason | R6: only `WatchRuntimeHost` needs `NSObject`. |
| `count + 1` off-by-one reads oddly | `repSchedule`: name it `nextRep`, with a comment. |
| No unit tests | Tests section (`Phase` tests moot once it is deleted). |
| **`Font.custom("SF Pro", size:)` bypasses Dynamic Type; two sizing mechanisms** | **Not covered before — added as R14.** |
| **Audio session failure only `print`ed** | **Not covered before — added to Phase 4.** |
| **`Ticker_Watch_AppApp` struct name** | **Not covered before — rename to `TickerWatchApp` in Phase 1 (R1 edits that file anyway).** |

| #   | Refactoring | Why |
|-----|-------------|-----|
| R14 | Replace `Font.custom("SF Pro", size:)` and the `imageFontSize` parameter with text styles (`.largeTitle`, `.title`, …) and `.imageScale` / `.font` on the symbol, so the UI follows Dynamic Type. Done with R9/R11, since those rewrite the same views. | Accessibility; AGENTS.md forbids forced font sizes. Also where the watch idle-screen fit gets checked. |

`docs/architecture.md` is stale in several places: wrong type names and file list; it calls
`Phase` a value type (it is a class); the tone timing is wrong (speech at engage, A3 at both
pauses, A4 at return); it lists `.system(size:)` fonts (the code uses `.custom("SF Pro")`); and
it says HealthKit is required for `workout-processing`. It also leaves out intents. **Rewrite it
at the end of Phase 1**, when the new structure exists, and mark the 2026-04-09 review as
describing the pre-Phase-0 code.

## Phases

**Phase 0 — toolchain, zero behavior change.** R0. Raise `IPHONEOS_DEPLOYMENT_TARGET` and
`WATCHOS_DEPLOYMENT_TARGET` to 26.0, `SWIFT_VERSION` to 6, `SWIFT_DEFAULT_ACTOR_ISOLATION` to
`MainActor`. Fix what strict concurrency flags in the existing code (`static var` intent
metadata -> `static let`; the `Timer` closure; the watch's `WKExtendedRuntimeSessionDelegate`
isolation). Build both targets, run on device, commit. Kept separate so a compiler-driven
change is never mixed with a design change.

*Done in `5c8f772`.* What it took: `static let` intent metadata; the `Timer` body wrapped in
`MainActor.assumeIsolated` (it is on the main run loop); `isolated deinit` on both
`CounterSession`s; `@MainActor` on the four template UI test classes. Default isolation and
approachable concurrency are set on the two app targets only, not the test targets. Both apps
and all test targets build with zero warnings.

Device note: a watch "Could not get trait set for device Watch6,11 with version 26.6" error
during verification was Xcode still copying symbols for a freshly updated watchOS (26.6.1),
then failing to reach the paired iPhone over the network — not the code. Wait for the copy
to finish in Devices and Simulators; connect the iPhone by cable if Xcode cannot find it.

**Phase 1 — structural, zero behavior change.** R3 -> R4 -> R1 -> R2 -> R6 -> R5 plumbing
-> R7, plus the `TickerWatchApp` rename. Ends with the `docs/architecture.md` rewrite.

The app must behave *identically* to today when this lands (ducking excepted, if it is
switched on here rather than Phase 4). This is most of the total effort and the checkpoint
worth verifying carefully, because a regression here breaks the feature that already works.
R7 moves here from Phase 2 because the `Task` driver replaces `Timer` as part of R4 anyway.

*As built:* everything above except R10 and R9's rename — `IntentMessages` and the name
`RepCounterView` stay until Phases 4 and 2. 22 unit tests (Swift Testing) pass on the iOS
simulator. Intentional differences from the old behavior, all on watchOS or at launch:

- If the extended runtime session ends unexpectedly or fails to start, the app now returns to
  idle and records Last Reps. Before, it spoke "N completed" but stayed on a frozen counting
  screen.
- After a normal Stop, invalidating the extended runtime session can no longer re-run the stop
  path (which could have spoken "N completed" twice).

The tone players and speech synthesizer are now made once, with the session at launch, rather
than at every Start.

On the watch, with Xcode's debugger attached, the first speech after launch can come many
seconds late — into rep 1 or 2, then "ready, 1, 2, 3" together — and some countdown and phase
labels are skipped. Phase 0 does the same under the debugger. Neither happens with Debug
executable unchecked in the scheme, or in a profiling (Release) build, so it is a debugger
effect, not an app bug: attaching pauses the app while the speech frameworks load. Check speech
timing on the watch without the debugger.

Device check: reps on iPhone and watch (ready countdown, numbers, tones, "N completed", Last
Reps), Stop by button and by Shortcut, and starting again after a Stop.

**Phase 2 — rest.** `restSchedule` + the Rest button on idle and reps screens + hand-off (R12)
+ generic `ActivityView` (R9) + Dynamic Type (R14) + iPhone keep-awake. Device check: a full 5:00 rest with the
iPhone left on screen and with the watch wrist-down.

**Phase 3 — stretch.** `stretchSchedule(hold:)` + round display + the Stretch button with a
remembered N (R11) + watch haptics.

**Phase 4 — Siri, intents, and audio.** `StartRest`, `StartStretch(hold:)`, `StretchHold`,
`TickerShortcuts` (R13), `@Dependency` wiring and delete `IntentMessages` (R10), retitle and
generalize `StopCounting`, `.playback` + `.duckOthers` with the ducking window, move audio
configuration into `ActivitySession.start()` and surface a failure there (the activity
screen shows that audio is unavailable instead of running silently).

Watch out in Phase 4: with a shared session, an intent's `perform()` can run **before any
view exists** when `openAppWhenRun` launches the app — another reason audio configuration
must live in `start()`. Test each phrase cold (app not running) and warm, on both devices.

## Tests

Use Swift Testing (`import Testing`); replace the empty XCTest stubs.

`Schedules.swift`:

- total duration per activity and per N (see the table above)
- a cue present at every expected boundary, and silence everywhere else
- haptics only on stretch / terminal cues, never on reps
- no spoken cue longer than the segment it occupies (the 3 s `Ready` windows)

`ActivitySession` with a fake clock, `CuePlayer`, and `RuntimeHost`:

- every cell of the hand-off table (resulting activity, `lastReps`, cues emitted)
- `RuntimeHost.acquire` called once across a reps -> rest hand-off; `release` once at the end
- a skipped tick skips the cue rather than delaying it
- rest and stretch finish themselves and release the runtime host

## Open / deferred

- Side announcements are assumed to be `"left"` / `"right"`. Alternatives: `"first side"` /
  `"second side"`, or just `"switch"`.
- Exact phrasing of the elapsed announcements (`"one minute thirty"` vs `"one thirty"`).
  Option: generate them with `Duration.UnitsFormatStyle` (`"1 minute, 30 seconds"`), which is
  localized for free — longer, but well within a 30 s gap.
- Spoken and on-screen strings should move to a String Catalog (none exists yet) with symbol
  keys, per AGENTS.md.
- Whether the idle screen should show anything about the last rest or stretch, the way it
  currently shows `"Last Reps: N"`.
- A "Start" (reps) button on the rest screen, mirroring Rest on the reps screen. Siri covers
  this leg for now.
- `AudioPlaybackIntent` could let iPhone intents start without foregrounding the app. Not
  pursued, since keep-awake assumes the app is on screen and the watch must be foregrounded.
- Chaining (set -> rest -> set as one hands-free circuit) was explicitly **rejected**: rest is
  manual-only. The `Schedule` model would support it later without rework.
