//
//  SegmentPosition.swift
//  Ticker
//

/// Where an activity is within one of its segments.
struct SegmentPosition: Equatable {
    /// Whole seconds since the segment started; 0 at its first second.
    let offset: Int
    /// Whole seconds left in the segment, counting the current one.
    let remaining: Int
    /// Zero-based pass through a repeating schedule's body. Always 0 in a lead-in or a sequence.
    let cycle: Int
}
