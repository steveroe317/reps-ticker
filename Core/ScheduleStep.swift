//
//  ScheduleStep.swift
//  Ticker
//

/// What an activity shows and plays at one second.
struct ScheduleStep: Equatable {
    let label: String
    let cues: [Cue]
}
