//
//  RepScheduleTests.swift
//  TickerTests
//

import Testing
@testable import Ticker

/// The rep schedule must reproduce the original `Phase` timer exactly.
@MainActor
struct RepScheduleTests {
    let schedule = Schedule.reps(leadIn: 3)

    @Test func labelsFollowTheCadence() {
        let labels = (0..<15).map { schedule.step(at: $0)?.label }
        #expect(labels == [
            "Ready 3", "Ready 2", "Ready 1",
            "Engage", "Engage", "Pause", "Back", "Back", "Pause",
            "Engage", "Engage", "Pause", "Back", "Back", "Pause",
        ])
    }

    @Test func cuesFallOnSegmentBoundaries() {
        let cues = (0..<10).map { schedule.step(at: $0)?.cues }
        #expect(cues == [
            [.speak("ready")], [], [],
            [.speak("1")], [], [.tone(.low)], [.tone(.high)], [], [.tone(.low)],
            [.speak("2")],
        ])
    }

    @Test func eachRepAnnouncesItsOwnNumber() {
        let engageSeconds = (0..<5).map { 3 + 6 * $0 }
        let cues = engageSeconds.map { schedule.step(at: $0)?.cues }
        #expect(cues == (1...5).map { [.speak(String($0))] })
    }

    @Test func countsRepsAsTheyComplete() {
        #expect(schedule.completedCycles(at: 0) == 0)
        #expect(schedule.completedCycles(at: 8) == 0)
        #expect(schedule.completedCycles(at: 9) == 1)
        #expect(schedule.completedCycles(at: 3 + 6 * 7) == 7)
        #expect(schedule.completedCycles(at: 3 + 6 * 7 - 1) == 6)
    }

    @Test func watchLeadInIsLonger() {
        let watch = Schedule.reps(leadIn: 5)
        let labels = (0..<6).map { watch.step(at: $0)?.label }
        #expect(labels == ["Ready 5", "Ready 4", "Ready 3", "Ready 2", "Ready 1", "Engage"])
        #expect(watch.step(at: 5)?.cues == [.speak("1")])
        #expect(watch.completedCycles(at: 11) == 1)
    }

    @Test func runsUntilStopped() {
        #expect(schedule.duration == nil)
        #expect(schedule.step(at: 100_000) != nil)
    }

    @Test func stopAnnouncesCompletedReps() {
        #expect(schedule.stopCues(0) == [])
        #expect(schedule.stopCues(1) == [.speak("1 completed")])
        #expect(schedule.stopCues(12) == [.speak("12 completed")])
    }
}
