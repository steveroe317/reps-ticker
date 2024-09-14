//
//  ContentModel.swift
//  Ticker
//
//  Created by Steve Roe on 7/11/24.
//

import AVFoundation
import SwiftUI

@Observable
/// Times an exercise set reps with auditory cues and counts.
///
/// This class is different in iOS/ipadOS and watchOS due to differences in background task
/// task handling, but much code is duplicated between the two classes.
///
/// TODO: Refactor to reduce duplicated code. Maybe use a protocol and a factory method in clients.
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
                self.soundEffects.replay(name: "a3-note")
            } else if (self.phase.atBack()) {
                self.soundEffects.replay(name: "a4-note")
            } else if (self.phase.atBackPause()) {
                self.soundEffects.replay(name: "a3-note")
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
