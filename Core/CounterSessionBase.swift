//
//  CounterSessionBase.swift
//  Ticker
//
//  Created by Steve Roe on 11/4/24.
//

import AVFoundation
import SwiftUI

@Observable
class CounterSessionBase: NSObject {
    var count = 0
    var phase = Phase()
    let sharedTimer = TimerSingleton.shared
    let soundEffects: SoundEffects = SoundEffects()
    let speaker = AVSpeechSynthesizer()
    
    func issueReadyAnnouncement() {
        speaker.speak(AVSpeechUtterance(string: "ready"))
    }
    
    func issueCompleteAnnouncement() {
        if self.count > 0 {
            speaker.speak(AVSpeechUtterance(string: "\(self.count) completed"))
        }
    }
    
    func makeCounterTimer() -> Timer {
        return Timer(timeInterval: 1, repeats: true) { _ in
            // The timer is scheduled on the main run loop, so it always fires on the main
            // thread. Replaced by a Task-based driver in Phase 1 (see plans/add-timers.md).
            MainActor.assumeIsolated {
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
        }
    }
}
