//
//  CuePlaying.swift
//  Ticker
//

/// Produces cues. Abstracted so `ActivitySession` can be tested without audio.
protocol CuePlaying {
    /// Produces each cue in order.
    func play(_ cues: [Cue])
}
