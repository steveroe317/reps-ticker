//
//  SoundEffects.swift
//  Ticker
//
//  Created by Steve Roe on 7/8/24.
//

import AVFoundation

/// Preloaded players for the cue tones.
final class SoundEffects {
    private let players: [Tone: AVAudioPlayer]

    init() {
        var players: [Tone: AVAudioPlayer] = [:]
        for tone in Tone.allCases {
            players[tone] = AVAudioPlayer.bundledWAV(named: tone.fileName)
        }
        self.players = players
    }

    /// Plays a tone. Does nothing if its sound file could not be loaded.
    func play(_ tone: Tone) {
        guard let player = players[tone] else { return }
        player.stop()
        player.play()
    }
}
