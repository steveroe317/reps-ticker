//
//  Segment.swift
//  Ticker
//

/// A span of whole seconds in an activity, with its own label and cues.
struct Segment {
    /// Length in seconds; at least 1.
    let duration: Int
    /// The on-screen label for each second of the segment.
    let label: (SegmentPosition) -> String
    /// The cues to play at each second of the segment; usually empty.
    let cues: (SegmentPosition) -> [Cue]

    init(
        duration: Int,
        label: @escaping (SegmentPosition) -> String,
        cues: @escaping (SegmentPosition) -> [Cue]
    ) {
        precondition(duration > 0, "A segment must last at least one second.")
        self.duration = duration
        self.label = label
        self.cues = cues
    }

    /// A segment with a fixed label whose cues all play at its first second.
    init(duration: Int, label: String, startCues: [Cue]) {
        self.init(
            duration: duration,
            label: { _ in label },
            cues: { $0.offset == 0 ? startCues : [] }
        )
    }
}
