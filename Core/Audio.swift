//
//  Audio.swift
//  Ticker
//
//  Created by Steve Roe on 7/3/24.
//

import AVFoundation
import Foundation

/// Creates an audio player for a specifc sound.
/// - Parameter filename: file containing the sound data.
/// - Returns: Audio player for the sound.
func makeAudioPlayer(filename: String) -> AVAudioPlayer? {
    let filepath = Bundle.main.path(forResource: filename, ofType: nil)
    let url: URL? = URL(fileURLWithPath: filepath!)
    var soundEffect: AVAudioPlayer? = nil
    if url != nil {
        do {
        soundEffect = try AVAudioPlayer(contentsOf: url!)
        }
        catch {
            soundEffect = nil
        }
    }
    return soundEffect
}
