//
//  CuePlayer.swift
//  Ticker
//

import AVFoundation

/// Plays cues as tones and speech.
final class CuePlayer: CuePlaying {
    private let soundEffects = SoundEffects()
    private let speaker = AVSpeechSynthesizer()

    func play(_ cues: [Cue]) {
        for cue in cues {
            switch cue {
            case .tone(let tone):
                soundEffects.play(tone)
            case .speak(let text):
                speaker.speak(AVSpeechUtterance(string: text))
            }
        }
    }
}
