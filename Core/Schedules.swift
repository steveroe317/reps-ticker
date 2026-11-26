//
//  Schedules.swift
//  Ticker
//

extension Schedule {
    /// Six-second reps — engage 2 s, pause 1 s, back 2 s, pause 1 s — after a "Ready" countdown.
    ///
    /// Speaks "ready" when the countdown starts and the number of each rep as it begins. Plays
    /// a low tone at each pause and a high tone at the start of the return. Stopping announces
    /// "N completed" once at least one rep is done.
    ///
    /// - Parameter leadIn: length of the "Ready" countdown in seconds; varies by platform.
    static func reps(leadIn: Int) -> Schedule {
        let ready = Segment(
            duration: leadIn,
            label: { "Ready \($0.remaining)" },
            cues: { $0.offset == 0 ? [.speak("ready")] : [] }
        )
        let engage = Segment(
            duration: 2,
            label: { _ in "Engage" },
            cues: { position in
                guard position.offset == 0 else { return [] }
                // `cycle` is the number of reps already completed, so the rep starting now is
                // one more.
                let nextRep = position.cycle + 1
                return [.speak(String(nextRep))]
            }
        )
        return .cycle(
            leadIn: [ready],
            body: [
                engage,
                Segment(duration: 1, label: "Pause", startCues: [.tone(.low)]),
                Segment(duration: 2, label: "Back", startCues: [.tone(.high)]),
                Segment(duration: 1, label: "Pause", startCues: [.tone(.low)]),
            ],
            stopCues: { completed in
                completed > 0 ? [.speak("\(completed) completed")] : []
            }
        )
    }
}
