//
//  Tone.swift
//  Ticker
//

/// The tones used for activity cues.
enum Tone: CaseIterable {
    /// A3, 220 Hz.
    case low
    /// A4, 440 Hz.
    case high

    /// Name of the bundled `.wav` file for the tone.
    var fileName: String {
        switch self {
        case .low: "A3-220Hz"
        case .high: "A4-440Hz"
        }
    }
}
