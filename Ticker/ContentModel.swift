//
//  ContentModel.swift
//  Ticker
//
//  Created by Steve Roe on 7/11/24.
//

import AVFoundation
import SwiftUI

@Observable
final class ContentModel: NSObject {
    var count = 0
    var phase = Phase()
    private var timer: Timer?
    let soundEffects: SoundEffects = SoundEffects()
    let speaker = AVSpeechSynthesizer()
    
    override init () {
        super.init()
        startCounting()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    private func startCounting() {
        speaker.speak(AVSpeechUtterance(string: "ready"))
        timer = Timer(timeInterval: 1, repeats: true) { _ in
            self.phase.advance()
            if self.phase.CycleCompleted() {
                self.count += 1
            }
            if (self.phase.atEngage()) {
                self.speaker.speak(AVSpeechUtterance(string: String(self.count + 1)))
            } else if (self.phase.atEngagePause()) {
                self.soundEffects.replay(name: "pause")
            } else if (self.phase.atBack()) {
                self.soundEffects.replay(name: "engage")
            } else if (self.phase.atBackPause()) {
                self.soundEffects.replay(name: "pause2")
            }
        }
        if timer != nil {
            RunLoop.main.add(timer!, forMode: .common)
        }
    }
    
    func stopCounting() {
        timer?.invalidate()
        timer = nil
    }
}
