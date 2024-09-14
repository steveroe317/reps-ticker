//
//  SoundEffects.swift
//  Ticker
//
//  Created by Steve Roe on 7/8/24.
//

import AVFoundation

/// Audio sound effects for rep phases.
class SoundEffects {
    var sounds = [
        "a4-note": makeAudioPlayer(filename: "A4-440Hz.wav"),
        "a3-note": makeAudioPlayer(filename: "A3-220Hz.wav"),
    ]
    
    func replay(name: String) {
        if let sound = sounds[name] {
            sound?.stop()
            sound?.play()
        }
    }
}
