//
//  SoundEffects.swift
//  Ticker
//
//  Created by Steve Roe on 7/8/24.
//

import AVFoundation

class SoundEffects {
    var sounds = [
        "engage": makeAudioPlayer(filename: "engage.wav"),
        "pause": makeAudioPlayer(filename: "pause.wav"),
        "return": makeAudioPlayer(filename: "return.wav"),
        "pause2": makeAudioPlayer(filename: "pause2.wav")
    ]
    
    func replay(name: String) {
        if let sound = sounds[name] {
            sound?.stop()
            sound?.play()
        }
    }
}
