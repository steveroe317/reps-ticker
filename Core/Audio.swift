//
//  Audio.swift
//  Ticker
//
//  Created by Steve Roe on 7/3/24.
//

import AVFoundation

extension AVAudioPlayer {
    /// Creates a player for a `.wav` file in the main bundle.
    /// - Parameter name: file name without the extension.
    /// - Returns: the player, or `nil` if the file is missing or unreadable.
    static func bundledWAV(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            return nil
        }
        return try? AVAudioPlayer(contentsOf: url)
    }
}
