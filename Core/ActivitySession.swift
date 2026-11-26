//
//  ActivitySession.swift
//  Ticker
//

import Foundation

/// Runs one activity at a time: drives its schedule from the clock, plays its cues, and holds
/// the platform runtime while it lasts.
///
/// The app creates one session and shares it through the environment. Views read it and call
/// `startReps()` and `stop()`; they never own it.
@Observable
final class ActivitySession {
    /// Whether an activity is running.
    private(set) var isActive = false
    /// The label for the current second, such as "Ready 3" or "Engage".
    private(set) var label = ""
    /// Completed cycles of the current activity: reps, for the rep counter.
    private(set) var count = 0
    /// Reps completed in the last rep activity that was stopped.
    private(set) var lastReps = 0

    @ObservationIgnored private let host: any RuntimeHost
    @ObservationIgnored private let cuePlayer: any CuePlaying
    @ObservationIgnored private var schedule: Schedule?
    /// The last second advanced to. Cues for it and any earlier second are never played again.
    @ObservationIgnored private var lastSecond = -1
    @ObservationIgnored private var ticker: Task<Void, Never>?
    /// Changes on every start and end, so callbacks and ticks left over from an earlier run do
    /// nothing.
    @ObservationIgnored private var run = 0

    /// - Parameters:
    ///   - host: keeps the app running during an activity.
    ///   - cuePlayer: plays every activity's cues, for the life of the app.
    init(host: any RuntimeHost, cuePlayer: any CuePlaying = CuePlayer()) {
        self.host = host
        self.cuePlayer = cuePlayer
    }

    /// Starts counting reps, unless an activity is already running.
    func startReps() {
        start(.reps(leadIn: host.leadIn))
    }

    /// Starts an activity, unless one is already running.
    ///
    /// The first second's label and cues take effect immediately. The clock starts once the
    /// runtime host is ready, so on watchOS the countdown waits for the extended runtime session.
    func start(_ schedule: Schedule) {
        guard !isActive else { return }
        run += 1
        let run = run
        self.schedule = schedule
        lastSecond = -1
        count = 0
        isActive = true
        advance(to: 0)
        guard isActive else { return }  // An empty sequence finishes at once.
        host.acquire(
            onReady: { [weak self] in
                guard let self, self.run == run else { return }
                startTicking(run: run)
            },
            onLost: { [weak self] in
                guard let self, self.run == run else { return }
                stop()
            }
        )
    }

    /// Stops the running activity, playing its stop cues. Does nothing if none is running.
    func stop() {
        guard isActive, let schedule else { return }
        if schedule.repeats {
            lastReps = count
        }
        cuePlayer.play(schedule.stopCues(count))
        end()
    }

    /// Moves the activity to a whole second since its clock started, updating the label and
    /// count and playing that second's cues.
    ///
    /// Seconds at or before the last one advanced to are ignored, so a late tick skips the
    /// cues it missed rather than playing them late. Finishes a non-repeating schedule that has
    /// reached its end. Called by the ticker; internal so tests can drive time directly.
    func advance(to second: Int) {
        guard isActive, let schedule, second > lastSecond else { return }
        lastSecond = second
        count = schedule.completedCycles(at: second)
        guard let step = schedule.step(at: second) else {
            cuePlayer.play(schedule.finishCues)
            end()
            return
        }
        label = step.label
        cuePlayer.play(step.cues)
    }

    /// Advances once per second, deriving each second from elapsed time on a monotonic clock
    /// rather than counting ticks, so a delayed tick never makes the activity lag.
    private func startTicking(run: Int) {
        let origin = ContinuousClock.now
        ticker = Task { [weak self] in
            var next = 1
            while true {
                do {
                    try await Task.sleep(
                        until: origin + .seconds(next),
                        tolerance: .zero,
                        clock: .continuous
                    )
                } catch {
                    return  // Cancelled by `end()`.
                }
                guard let self, self.run == run else { return }
                let second = Int((ContinuousClock.now - origin) / .seconds(1))
                advance(to: second)
                next = max(second, next) + 1
            }
        }
    }

    private func end() {
        run += 1
        ticker?.cancel()
        ticker = nil
        schedule = nil
        isActive = false
        host.relinquish()
    }
}
