//
//  RecordingCuePlayer.swift
//  TickerTests
//

@testable import Ticker

/// A cue player that records cues instead of playing them.
@MainActor
final class RecordingCuePlayer: CuePlaying {
    private(set) var played: [Cue] = []

    func play(_ cues: [Cue]) {
        played += cues
    }

    /// Forgets the cues recorded so far.
    func reset() {
        played = []
    }
}
