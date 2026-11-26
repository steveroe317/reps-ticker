//
//  ActivitySessionTests.swift
//  TickerTests
//

import Testing
@testable import Ticker

/// Drives the session second by second with `advance(to:)`. The fake host never reports ready,
/// so the real clock never ticks.
@MainActor
struct ActivitySessionTests {
    let host = FakeRuntimeHost()
    let cues = RecordingCuePlayer()
    let session: ActivitySession

    init() {
        session = ActivitySession(host: host, cuePlayer: cues)
    }

    @Test func startShowsTheCountdownAndSaysReady() {
        session.startReps()
        #expect(session.isActive)
        #expect(session.label == "Ready 3")
        #expect(session.count == 0)
        #expect(cues.played == [.speak("ready")])
        #expect(host.acquireCount == 1)
    }

    @Test func eachSecondPlaysItsCuesOnce() {
        session.startReps()
        cues.reset()
        session.advance(to: 3)
        session.advance(to: 3)
        session.advance(to: 2)
        #expect(session.label == "Engage")
        #expect(cues.played == [.speak("1")])
    }

    @Test func aLateTickSkipsMissedCues() {
        session.startReps()
        cues.reset()
        session.advance(to: 9)
        #expect(cues.played == [.speak("2")])
        #expect(session.count == 1)
    }

    @Test func stopRecordsRepsAndAnnouncesThem() {
        session.startReps()
        session.advance(to: 15)
        cues.reset()
        session.stop()
        #expect(!session.isActive)
        #expect(session.lastReps == 2)
        #expect(cues.played == [.speak("2 completed")])
        #expect(host.relinquishCount == 1)
    }

    @Test func stopBeforeTheFirstRepIsSilent() {
        session.startReps()
        session.advance(to: 4)
        cues.reset()
        session.stop()
        #expect(session.lastReps == 0)
        #expect(cues.played == [])
    }

    @Test func stopWhenIdleDoesNothing() {
        session.stop()
        #expect(host.relinquishCount == 0)
        #expect(cues.played == [])
    }

    @Test func startWhileRunningIsIgnored() {
        session.startReps()
        session.advance(to: 9)
        session.startReps()
        #expect(session.count == 1)
        #expect(host.acquireCount == 1)
    }

    @Test func losingTheRuntimeStopsTheActivity() {
        session.startReps()
        session.advance(to: 9)
        host.loseRuntime()
        #expect(!session.isActive)
        #expect(session.lastReps == 1)
        #expect(cues.played.last == .speak("1 completed"))
    }

    @Test func callbacksFromAnEarlierRunAreIgnored() {
        session.startReps()
        session.stop()
        session.startReps()
        host.loseRuntime(fromAcquire: 0)
        #expect(session.isActive)
    }

    /// Uses the real clock: about 3.5 s, enough to reach the first rep.
    @Test func theClockAdvancesOncePerSecond() async throws {
        let session = ActivitySession(host: PreviewRuntimeHost(), cuePlayer: cues)
        session.startReps()
        try await Task.sleep(for: .milliseconds(3_500))
        #expect(session.label == "Engage")
        #expect(cues.played == [.speak("ready"), .speak("1")])
        session.stop()
        #expect(!session.isActive)
    }

    @Test func aSequenceFinishesByItself() {
        session.startReps()
        session.advance(to: 9)
        session.stop()
        cues.reset()
        session.start(.sequence(
            [Segment(duration: 2, label: "Rest", startCues: [.speak("rest")])],
            finishCues: [.speak("rest finished")]
        ))
        session.advance(to: 1)
        #expect(session.isActive)
        session.advance(to: 2)
        #expect(!session.isActive)
        #expect(cues.played == [.speak("rest"), .speak("rest finished")])
        #expect(session.lastReps == 1)
        #expect(host.relinquishCount == 2)
    }
}
