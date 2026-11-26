//
//  ScheduleTests.swift
//  TickerTests
//

import Testing
@testable import Ticker

@MainActor
struct ScheduleTests {
    /// Labels each second with its position, e.g. "B 1/2" for offset 1, 2 remaining.
    private func positionSegment(_ name: String, duration: Int) -> Segment {
        Segment(
            duration: duration,
            label: { "\(name) \($0.offset)/\($0.remaining)" },
            cues: { _ in [] }
        )
    }

    @Test func sequencePlaysOnceThenEnds() {
        let schedule = Schedule.sequence(
            [
                Segment(duration: 2, label: "A", startCues: [.speak("a")]),
                Segment(duration: 1, label: "B", startCues: [.tone(.high)]),
            ],
            finishCues: [.speak("done")]
        )
        #expect(schedule.duration == 3)
        #expect(schedule.step(at: 0) == ScheduleStep(label: "A", cues: [.speak("a")]))
        #expect(schedule.step(at: 1) == ScheduleStep(label: "A", cues: []))
        #expect(schedule.step(at: 2) == ScheduleStep(label: "B", cues: [.tone(.high)]))
        #expect(schedule.step(at: 3) == nil)
        #expect(schedule.completedCycles(at: 2) == 0)
        #expect(schedule.finishCues == [.speak("done")])
        #expect(schedule.stopCues(5) == [])
    }

    @Test func positionsCountWithinEachSegment() {
        let schedule = Schedule.sequence(
            [positionSegment("A", duration: 2), positionSegment("B", duration: 3)],
            finishCues: []
        )
        let labels = (0..<5).map { schedule.step(at: $0)?.label }
        #expect(labels == ["A 0/2", "A 1/1", "B 0/3", "B 1/2", "B 2/1"])
    }

    @Test func cycleIndexCountsPassesThroughTheBody() {
        let schedule = Schedule.cycle(
            leadIn: [positionSegment("L", duration: 2)],
            body: [
                Segment(duration: 2, label: { "C\($0.cycle)" }, cues: { _ in [] }),
            ],
            stopCues: { _ in [] }
        )
        let labels = (0..<7).map { schedule.step(at: $0)?.label }
        #expect(labels == ["L 0/2", "L 1/1", "C0", "C0", "C1", "C1", "C2"])
    }

    @Test func emptySequenceEndsImmediately() {
        let schedule = Schedule.sequence([], finishCues: [])
        #expect(schedule.duration == 0)
        #expect(schedule.step(at: 0) == nil)
    }
}
