//
//  Cue.swift
//  Ticker
//

/// Something the user hears at a point in an activity.
///
/// Schedules declare cues; `CuePlayer` decides how to produce them.
enum Cue: Equatable {
    /// Plays a short tone.
    case tone(Tone)
    /// Speaks a short phrase.
    case speak(String)
}
