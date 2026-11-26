//
//  Schedule.swift
//  Ticker
//

/// The timeline of an activity: its segments, and what to play when it is stopped or finishes.
///
/// A schedule is pure data. `ActivitySession` asks it what happens at each whole second since
/// the activity started.
struct Schedule {
    /// Segments played once at the start.
    let leadIn: [Segment]
    /// Segments after the lead-in. Repeated until stopped when `repeats` is true; otherwise
    /// played once, after which the activity finishes.
    let body: [Segment]
    /// Whether `body` repeats.
    let repeats: Bool
    /// Cues for when the user stops the activity, given the number of completed cycles.
    let stopCues: (_ completedCycles: Int) -> [Cue]
    /// Cues for when a non-repeating schedule reaches its end.
    let finishCues: [Cue]

    /// A schedule whose body repeats until the user stops it, such as reps.
    static func cycle(
        leadIn: [Segment],
        body: [Segment],
        stopCues: @escaping (_ completedCycles: Int) -> [Cue]
    ) -> Schedule {
        precondition(!body.isEmpty, "A repeating schedule needs at least one segment.")
        return Schedule(
            leadIn: leadIn,
            body: body,
            repeats: true,
            stopCues: stopCues,
            finishCues: []
        )
    }

    /// A schedule that plays its segments once and then finishes on its own.
    static func sequence(_ segments: [Segment], finishCues: [Cue]) -> Schedule {
        Schedule(
            leadIn: [],
            body: segments,
            repeats: false,
            stopCues: { _ in [] },
            finishCues: finishCues
        )
    }

    /// Total length in seconds, or `nil` for a schedule that repeats.
    var duration: Int? {
        repeats ? nil : leadInDuration + bodyDuration
    }

    /// The number of full passes through the body completed at a second. Always 0 for a
    /// schedule that does not repeat.
    func completedCycles(at second: Int) -> Int {
        guard repeats, second >= leadInDuration else { return 0 }
        return (second - leadInDuration) / bodyDuration
    }

    /// The label and cues at a whole second since the start, or `nil` once a non-repeating
    /// schedule has ended.
    func step(at second: Int) -> ScheduleStep? {
        precondition(second >= 0, "Seconds are counted from the start of the activity.")
        if second < leadInDuration {
            return Self.step(in: leadIn, at: second, cycle: 0)
        }
        let bodySecond = second - leadInDuration
        if repeats {
            return Self.step(
                in: body,
                at: bodySecond % bodyDuration,
                cycle: bodySecond / bodyDuration
            )
        }
        return Self.step(in: body, at: bodySecond, cycle: 0)
    }

    private var leadInDuration: Int {
        leadIn.reduce(0) { $0 + $1.duration }
    }

    private var bodyDuration: Int {
        body.reduce(0) { $0 + $1.duration }
    }

    /// Finds the segment containing `second` (counted from the start of `segments`), or `nil`
    /// if `second` is past their end.
    private static func step(in segments: [Segment], at second: Int, cycle: Int) -> ScheduleStep? {
        var start = 0
        for segment in segments {
            let end = start + segment.duration
            if second < end {
                let position = SegmentPosition(
                    offset: second - start,
                    remaining: end - second,
                    cycle: cycle
                )
                return ScheduleStep(label: segment.label(position), cues: segment.cues(position))
            }
            start = end
        }
        return nil
    }
}
