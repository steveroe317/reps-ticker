//
//  ContentModel.swift
//  Ticker Watch App
//
//  Created by Steve Roe on 7/11/24.
//

import AVFoundation
import SwiftUI

/// Times an exercise set reps with auditory cues and counts.
///
/// This class is different in iOS/ipadOS and watchOS due to differences in background task
/// task handling.
@Observable
final class CounterSession: CounterSessionBase {
    private var session: WKExtendedRuntimeSession!

    override init () {
        super.init()
        startCounting()
    }

    deinit {
        sharedTimer.timer?.invalidate()
        stopCounting()
        stopSession()
    }
    
    private func startCounting() {
        guard sharedTimer.timer == nil else {
            return
        }
        issueReadyAnnouncement()
        startSession()
   }
    
    func stopCounting() {
        sharedTimer.timer?.invalidate()
        sharedTimer.timer = nil
        stopSession()
        issueCompleteAnnouncement()
    }
    
    private func startSession() {
        session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
    }
    
    private func stopSession() {
        session?.invalidate()
        session = nil
    }
}

extension CounterSession: WKExtendedRuntimeSessionDelegate {
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        sharedTimer.timer = makeCounterTimer()
        if sharedTimer.timer != nil {
            RunLoop.main.add(sharedTimer.timer!, forMode: .common)
        }
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: (any Error)?) {
        stopCounting()
    }
}
