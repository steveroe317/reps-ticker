//
//  ContentModel.swift
//  Ticker Watch App
//
//  Created by Steve Roe on 7/11/24.
//

import AVFoundation
import SwiftUI

@Observable
final class ContentModel: NSObject {
    var count = 0
    var phase = Phase()
    private var session: WKExtendedRuntimeSession!
    private var timer: Timer!
    let soundEffects: SoundEffects = SoundEffects()
    let speaker = AVSpeechSynthesizer()
    
    override init () {
        super.init()
        startCounting()
    }
    
    private func startCounting() {
        session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        speaker.speak(AVSpeechUtterance(string: "ready"))
    }
    
    func stopCounting() {
        session.invalidate()
    }
}

extension ContentModel: WKExtendedRuntimeSessionDelegate {
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("didStart")
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
        RunLoop.main.add(timer, forMode: .common)
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: (any Error)?) {
        timer.invalidate()
        timer = nil
    }
}
